# encoding: UTF-8
# Plugins/ar_addons/ar_redraw/mat_redraw
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'sketchup'
require 'set'

module ARAddons
  module ARRedraw
    module MatRedraw
      extend self

      MODEL_ATTR_DICT = 'ar_mat_redraw'.freeze
      MODEL_ATTR_KEY  = 'last_targets'.freeze

      @patched = false
      @debug   = false

      def log(msg)   ; puts("[AR_mat_redraw] #{msg}") rescue nil ; end
      def trace(msg) ; return unless @debug ; log(msg)           ; end

      # ---------- helpers ----------
      def pid(ent)
        ent.respond_to?(:persistent_id) ? ent.persistent_id : ent.object_id
      end

      def tag_visible?(ent)
        lay = (ent.respond_to?(:layer) ? ent.layer : nil) rescue nil
        return true unless lay
        return true unless lay.respond_to?(:visible?)
        lay.visible?
      rescue
        true
      end

      def hidden_instance?(ent)
        return false unless ent.is_a?(Sketchup::ComponentInstance) || ent.is_a?(Sketchup::Group)
        (ent.hidden? rescue false) || (tag_visible?(ent) == false)
      end

      def groove_def_name?(ent)
        return false unless ent.is_a?(Sketchup::ComponentInstance)
        dn = (ent.definition&.name || '').to_s
        !dn.empty? && dn.downcase.include?('groove')
      end

      def children_of(ent)
        ents =
          case ent
          when Sketchup::ComponentInstance then ent.definition.entities
          when Sketchup::Group             then ent.entities
          else nil
          end
        return [] unless ents
        ents.grep(Sketchup::ComponentInstance) + ents.grep(Sketchup::Group)
      end

      # корни — предпочтительно выделение; если пусто — активный контекст (active_entities)
      def roots_for_scan
        m = Sketchup.active_model
        return [] unless m

        sel = m.selection
        roots = (sel.grep(Sketchup::ComponentInstance) + sel.grep(Sketchup::Group)).uniq
        return roots unless roots.empty?

        ents = m.active_entities
        (ents.grep(Sketchup::ComponentInstance) + ents.grep(Sketchup::Group)).uniq
      end

      # DFS по всем уровням: искать скрытые инстансы с 'groove' в имени definition
      def dfs_collect_hidden_grooves(node, out, visited)
        return unless node
        key = node.object_id
        return if visited.include?(key)
        visited << key

        children_of(node).each do |ch|
          if ch.is_a?(Sketchup::ComponentInstance)
            if hidden_instance?(ch) && groove_def_name?(ch)
              out << ch
            end
          end
          dfs_collect_hidden_grooves(ch, out, visited)
        end
      end

      def find_hidden_groove_targets
        roots   = roots_for_scan
        targets = []
        visited = Set.new
        roots.each { |r| dfs_collect_hidden_grooves(r, targets, visited) }

        # де-дуп по PID
        uniq = {}
        targets.each { |i| uniq[pid(i)] = i }
        result = uniq.values

        save_last_target_pids(result)
        result
      end

      def save_last_target_pids(instances)
        return if instances.nil? || instances.empty?
        m = Sketchup.active_model
        return unless m
        pids = instances.map { |i| pid(i) }
        m.set_attribute(MODEL_ATTR_DICT, MODEL_ATTR_KEY, pids.join(','))
        trace "Saved PIDs: #{pids.size}"
      rescue => e
        trace "save_last_target_pids error: #{e.class}: #{e.message}"
      end

      def read_last_target_pids
        m = Sketchup.active_model
        return [] unless m
        raw = m.get_attribute(MODEL_ATTR_DICT, MODEL_ATTR_KEY)
        return [] if raw.to_s.strip.empty?
        raw.to_s.split(',').map! { |s| Integer(s) rescue s.to_s }
      rescue
        []
      end

      def instances_by_pid(pids)
        return [] if pids.nil? || pids.empty?
        m = Sketchup.active_model
        return [] unless m
        found = []
        pset  = pids.is_a?(Set) ? pids : pids.to_set
        m.definitions.each do |d|
          d.instances.each do |inst|
            begin
              found << inst if pset.include?(pid(inst))
            rescue
            end
          end
        end
        found
      end

      # ---------- HtmlDialog callbacks (подписка на событие окна материалов) ----------
      #
      # Окно материалов вызывает:
      #   sketchup.redraw_children()     — мы перехватываем и делаем поиск groove + redraw
      #   sketchup.force_redraw()        — то же самое как синоним
      #
      def ensure_callbacks!
        return if @patched
        return unless defined?(UI::HtmlDialog)

        UI::HtmlDialog.class_eval do
          alias_method :ar_mat_orig_initialize, :initialize

          def initialize(*args, **kwargs, &block)
            ar_mat_orig_initialize(*args, **kwargs, &block)

            # Главный хук: событие «перерисовать после наложения материала»
            add_action_callback('redraw_children') do |_dlg, *_|
              begin
                targets = ARAddons::ARRedraw::MatRedraw.find_hidden_groove_targets
                ARAddons::ARRedraw.redraw_batch(targets, 'Redraw (Mat/Groove)')
              rescue => e
                puts "[AR_mat_redraw] redraw_children err: #{e.class}: #{e.message}"
              end
            end

            # Синоним на случай другого вызова из окна
            add_action_callback('force_redraw') do |_dlg, *_|
              begin
                targets = ARAddons::ARRedraw::MatRedraw.find_hidden_groove_targets
                ARAddons::ARRedraw.redraw_batch(targets, 'Redraw (Mat/Groove)')
              rescue => e
                puts "[AR_mat_redraw] force_redraw err: #{e.class}: #{e.message}"
              end
            end

            # Опционально: восстановить и перерисовать по последнему списку PID
            add_action_callback('redraw_grooves_from_memory') do |_dlg, *_|
              begin
                pids = ARAddons::ARRedraw::MatRedraw.read_last_target_pids
                inst = ARAddons::ARRedraw::MatRedraw.instances_by_pid(pids)
                ARAddons::ARRedraw.redraw_batch(inst, 'Redraw (Mat/Groove)')
              rescue => e
                puts "[AR_mat_redraw] redraw_grooves_from_memory err: #{e.class}: #{e.message}"
              end
            end
          end
        end

        @patched = true
        log 'HtmlDialog patched: subscribed to material overlay events (redraw_children / force_redraw)'
      rescue => e
        log "ensure_callbacks! error: #{e.class}: #{e.message}"
      end
    end
  end
end

# активируем подписку при загрузке файла
ARAddons::ARRedraw::MatRedraw.ensure_callbacks!
