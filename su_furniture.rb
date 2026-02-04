# su_furniture.rb
# SU_Furniture — disabled-by-default, no menu, ultra-safe
# This build does not auto-enable anything and contains no UI menu code.
# It only attaches a post-commit ModelObserver when you explicitly enable it.
#
# Usage (Ruby Console):
#   load 'su_furniture.rb'               # if needed
#   SU_Furniture.enable                  # turn on
#   SU_Furniture.disable                 # turn off
#   SU_Furniture.state                   # 0=disabled, 1=enabled

require 'set'

module SU_Furniture
  extend self

  @state = 0  # 0=disabled, 1=enabled
  @known_ids = Set.new
  @snapshot_pending = false

  def log(msg); puts "[SU_Furniture] #{msg}"; rescue nil; end

  # --- Minimal tracker (no Entities/Selection/Layers/Pages/Tools observers) ---
  class ModelTracker < Sketchup::ModelObserver
    def onTransactionCommit(model)
      SU_Furniture.snapshot_and_diff(model)
    end
    def onTransactionUndoRedo(model)
      SU_Furniture.snapshot_and_diff(model)
    end
    def onActivateModel(model)
      SU_Furniture.refresh_snapshot(model)
    end
  end

  def tracker; $SUF_ModelTracker ||= ModelTracker.new; end

  # --- Public API ---
  def enable
    return if @state == 1
    model = Sketchup.active_model
    begin
      model.add_observer(tracker)
    rescue => e
      log "attach tracker error: #{e.message}"
    end
    refresh_snapshot(model)
    @state = 1
    log "ENABLED"
  end

  def disable
    return if @state == 0
    model = Sketchup.active_model
    begin
      model.remove_observer(tracker)
    rescue => e
      log "detach tracker error: #{e.message}"
    end
    @state = 0
    log "DISABLED"
  end

  def state
    @state
  end

  # --- Snapshot & diff (no callbacks invoked; diagnostic safe) ---
  def refresh_snapshot(model)
    @known_ids = enumerate_top_level_ids(model)
    log "Snapshot size=#{@known_ids.size}"
  end

  def snapshot_and_diff(model)
    return if @snapshot_pending || @state == 0
    @snapshot_pending = true
    UI.start_timer(0.05, false) do
      begin
        current = enumerate_top_level_ids(model)
        added = current - @known_ids
        log "Detected added (#{added.size}) post-commit" if added.any?
        @known_ids = current
      ensure
        @snapshot_pending = false
      end
    end
  end

  def enumerate_top_level_ids(model)
    ids = Set.new
    model.entities.to_a.each { |e| ids << e.persistent_id rescue nil }
    ids
  end

  # Convenience aliases matching older API if you used add_remove_observers
  def add_remove_observers(state)
    if state.to_i == 1 then enable else disable end
  end

  # On file load: do nothing (disabled by default)
  log 'Loaded su_furniture.rb (disabled by default, no menu)'
end
