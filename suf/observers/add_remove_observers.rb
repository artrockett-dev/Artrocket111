# su_furniture.rb
# Hardened against crashes during component insertion:
# - Wrap EntitiesObserver with a safe proxy that defers onElementAdded via UI.start_timer
#   to avoid re-entrant edits while SketchUp/Qt are mutating the model.
# - Global, idempotent observer management with nil guards.
# - One-time initialization for parameters/presets (won't run during add events).

module SU_Furniture
  extend self

  @observers_state = 0 # 0=disabled, 1=enabled
  @observed = { selection:true, entities:false, layers:false, pages:false, tools:false }
  @init_done = false

  # ---------------- Safe wrappers ----------------

  # Wraps an EntitiesObserver and defers onElementAdded to the next tick; guards reentrancy.
  class SUFSafeEntitiesObserver < Sketchup::EntitiesObserver
    def initialize(inner)
      @inner = inner
      @busy  = false
    end

    def onElementAdded(entities, entity)
      return unless @inner && @inner.respond_to?(:onElementAdded)
      # Avoid re-entrancy during bulk/component insert
      return if @busy
      @busy = true
      UI.start_timer(0.0, false) do
        begin
          @inner.onElementAdded(entities, entity)
        rescue => e
          # Swallow to prevent hard crash; optionally log e.message
        ensure
          @busy = false
        end
      end
    end

    # Forward all other callbacks safely
    def method_missing(name, *args, &blk)
      if @inner && @inner.respond_to?(name)
        begin
          @inner.send(name, *args, &blk)
        rescue => e
          # swallow
        end
      else
        super
      end
    end

    def respond_to_missing?(name, include_private=false)
      (@inner && @inner.respond_to?(name, include_private)) || super
    end
  end

  # Generic safe wrapper for other observer types.
  module SUFSafeForwarder
    def initialize(inner)
      @inner = inner
    end
    def method_missing(name, *args, &blk)
      if @inner && @inner.respond_to?(name)
        begin
          @inner.send(name, *args, &blk)
        rescue => e
        end
      else
        super
      end
    end
    def respond_to_missing?(name, include_private=false)
      (@inner && @inner.respond_to?(name, include_private)) || super
    end
  end

  class SUFSafeSelectionObserver < Sketchup::SelectionObserver
    include SUFSafeForwarder
  end
  class SUFSafeLayersObserver < Sketchup::LayersObserver
    include SUFSafeForwarder
  end
  class SUFSafePagesObserver < Sketchup::PagesObserver
    include SUFSafeForwarder
  end
  class SUFSafeToolsObserver < Sketchup::ToolsObserver
    include SUFSafeForwarder
  end

  # ---------------- Observer getters ----------------

  def selection_observer
    return nil unless defined?(SUFSelectionObserver)
    $SUFSelectionObserver ||= SUFSafeSelectionObserver.new(SUFSelectionObserver.new)
  end

  def entities_observer
    return nil unless defined?(SUFEntitiesObserver)
    base = SUFEntitiesObserver.new
    $SUFEntitiesObserver ||= SUFSafeEntitiesObserver.new(base)
  end

  def layers_observer
    return nil unless defined?(SUFLayersObserver)
    $SUFLayersObserver ||= SUFSafeLayersObserver.new(SUFLayersObserver.new)
  end

  def pages_observer
    return nil unless defined?(SUFPagesObserver)
    $SUFPagesObserver ||= SUFSafePagesObserver.new(SUFPagesObserver.new)
  end

  def tools_observer
    return nil unless defined?(SUFToolsObserver)
    $SUFToolsObserver ||= SUFSafeToolsObserver.new(SUFToolsObserver.new)
  end

  # ---------------- Public API ----------------

  def add_remove_observers(state)
    model = Sketchup.active_model
    if state == 1
      add_observers(model)
      @observers_state = 1
    else
      remove_observers(model)
      @observers_state = 0
    end
    nil
  end

  def observers_state
    @observers_state
  end

  def observed
    @observed
  end

  def add_observers(model = Sketchup.active_model)
    return unless model

    # Attach observers idempotently
    if selection_observer && !@observed[:selection]
      safe_add_observer(model.selection, selection_observer) { @observed[:selection] = true }
    end

    if entities_observer && !@observed[:entities]
      safe_add_observer(model.entities,  entities_observer)  { @observed[:entities] = true }
    end

    if layers_observer && !@observed[:layers]
      safe_add_observer(model.layers,    layers_observer)    { @observed[:layers] = true }
    end

    if pages_observer && !@observed[:pages]
      safe_add_observer(model.pages,     pages_observer)     { @observed[:pages] = true }
    end

    if tools_observer && !@observed[:tools]
      safe_add_observer(model.tools,     tools_observer)     { @observed[:tools] = true }
    end

    # Model observer (not wrapped, but guarded)
    begin
      model.add_observer(SUFModelObserver.new) if defined?(SUFModelObserver)
    rescue
    end

    # One-time initialization ONLY (prevents edits during entity-added paths)
    unless @init_done
      close_dialogs_if_any
      one_time_initialize(model)
      @init_done = true
    end

    nil
  end

  def remove_observers(model = Sketchup.active_model)
    return unless model
    # safe_remove_observer(model.selection, selection_observer) if @observed[:selection]
    # @observed[:selection] = false

    safe_remove_observer(model.entities,  entities_observer)  if @observed[:entities]
    @observed[:entities] = false

    safe_remove_observer(model.layers,    layers_observer)    if @observed[:layers]
    @observed[:layers] = false

    safe_remove_observer(model.pages,     pages_observer)     if @observed[:pages]
    @observed[:pages] = false

    safe_remove_observer(model.tools,     tools_observer)     if @observed[:tools]
    @observed[:tools] = false
  end

  def add_new_observers(model = Sketchup.active_model)
    return unless model
    remove_observers(model)
    # Reset singleton wrappers
    $SUFSelectionObserver = nil
    $SUFEntitiesObserver  = nil
    $SUFLayersObserver    = nil
    $SUFPagesObserver     = nil
    $SUFToolsObserver     = nil
    @observed.keys.each { |k| @observed[k] = false }
    add_observers(model)
  end

  # ---------------- Internals ----------------

  def safe_add_observer(target, observer)
    return unless target && observer
    begin
      target.add_observer(observer)
      yield if block_given?
    rescue
    end
  end

  def safe_remove_observer(target, observer)
    return unless target && observer
    begin
      target.remove_observer(observer)
    rescue
    end
  end

  def close_dialogs_if_any
    begin; $dlg_param&.close if $dlg_param.respond_to?(:visible?) && $dlg_param.visible?; rescue; end
    begin; $dlg_suf&.close   if $dlg_suf.respond_to?(:visible?)   && $dlg_suf.visible?;   rescue; end
    begin; $dlg_spec&.close  if $dlg_spec.respond_to?(:visible?)  && $dlg_spec.visible?;  rescue; end
  end

  def one_time_initialize(model)
    # Parameter load (safe & non re-entrant)
    load_parameters_into_model(model)
    # Presets setup only if empty
    set_opencutlist_presets(model)
  end

  def load_parameters_into_model(model)
    param_temp_path = Sketchup.read_default('SUF', 'PARAM_TEMP_PATH')
    candidates = []
    candidates << File.join(param_temp_path, 'parameters.dat') if param_temp_path && File.file?(File.join(param_temp_path, 'parameters.dat'))
    if defined?(TEMP_PATH) && TEMP_PATH && File.file?(File.join(TEMP_PATH, 'SUF', 'parameters.dat'))
      candidates << File.join(TEMP_PATH, 'SUF', 'parameters.dat')
    end
    if defined?(PATH) && PATH && File.file?(File.join(PATH, 'parameters', 'parameters.dat'))
      candidates << File.join(PATH, 'parameters', 'parameters.dat')
    end

    path_param = candidates.find { |p| File.file?(p) }
    return unless path_param

    lines = []
    begin
      lines = File.readlines(path_param, chomp: true)
    rescue
      return
    end

    begin
      model.start_operation('SUF - Load Parameters', true, false, true)

      dicts = model.attribute_dictionaries
      begin
        dicts.delete('su_parameters') if dicts && dicts['su_parameters']
      rescue
      end

      dict = model.attribute_dictionary('su_parameters', true)

      lines.each do |line|
        next if line.nil? || line.strip.empty? || line.strip.start_with?('#', ';')
        next unless line.include?('=')
        key, value = line.split('=', 2)
        key = key.to_s.strip
        value = value.to_s.strip
        next if key.empty?
        model.set_attribute('su_parameters', key, value)
      end
    ensure
      begin
        model.commit_operation
      rescue
        begin; model.abort_operation; rescue; end
      end
    end
  end

  def set_opencutlist_presets(model)
    begin
      current = model.get_attribute('ladb_opencutlist', 'core.presets', nil)
      if current.nil? || current.strip == '{}' || current.strip.empty?
        new_presets = '{"cutlist_options":{"0":{"auto_orient":true,"smart_material":true,"dynamic_attributes_name":true,"part_number_with_letters":false,"part_number_sequence_by_group":true,"part_folding":false,"hide_entity_names":false,"hide_tags":false,"hide_cutting_dimensions":false,"hide_bbox_dimensions":false,"hide_untyped_material_dimensions":false,"hide_final_areas":true,"hide_edges":false,"minimize_on_highlight":true,"part_order_strategy":"name>-length>-width>-thickness>-count>-edge_pattern>tags","dimension_column_order_strategy":"length>width>thickness","tags":[""],"hidden_group_ids":[]}}}'
        model.set_attribute('ladb_opencutlist', 'core.presets', new_presets)
      end
    rescue
    end
  end
end
