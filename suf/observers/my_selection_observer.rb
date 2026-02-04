# =============================================================
# === Observers connected to your dialog ($dlg_suf) ============
# =============================================================

class MySelectionObserver < Sketchup::SelectionObserver
  def onSelectionBulkChange(selection)
    puts "✅ Selection changed"
    send_to_dialog("set_position_att")
  end

  private

  def send_to_dialog(action)
    if defined?($dlg_suf) && $dlg_suf
      begin
        $dlg_suf.execute_script(%Q(window.sketchup.get_data("#{action}");))
        puts "➡️ Sent to JS: #{action}"
      rescue => e
        puts "⚠️ JS call failed: #{e.message}"
      end
    else
      puts "⚠️ $dlg_suf not defined or not accessible."
    end
  end
end


class MyAppObserver < Sketchup::AppObserver
  def onNewModel(model)
    puts "✅ New model created"
    attach_selection_observer(model)
    send_to_dialog("onNewModel")
  end

  def onOpenModel(model)
    puts "✅ Model opened"
    attach_selection_observer(model)
    send_to_dialog("onOpenModel")
  end

  private

  def send_to_dialog(action)
    if defined?($dlg_suf) && $dlg_suf
      begin
        $dlg_suf.execute_script(%Q(window.sketchup.get_data("#{action}");))
        puts "➡️ Sent to JS: #{action}"
      rescue => e
        puts "⚠️ JS call failed: #{e.message}"
      end
    else
      puts "⚠️ $dlg_suf not defined or not accessible."
    end
  end

  def attach_selection_observer(model)
    $sel_observer ||= MySelectionObserver.new
    model.selection.add_observer($sel_observer)
    puts "✅ Selection observer attached to model."
  end
end

# =============================================================
# === Keep observers alive and attach globally ================
# =============================================================

$app_observer ||= MyAppObserver.new
$sel_observer ||= MySelectionObserver.new

Sketchup.add_observer($app_observer)
Sketchup.active_model.selection.add_observer($sel_observer)

puts "✅ Observers attached and linked to $dlg_suf."
