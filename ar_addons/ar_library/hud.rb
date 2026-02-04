# encoding: UTF-8
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'sketchup'

module ARLIB
  module HUD
    extend self

    # PNG дублируем поверх того же места (если метод SU доступен)
    PNG_PATH = File.join(File.dirname(__FILE__), 'html', 'icons', 'hud_rotate.png').freeze

    # Базовая геометрия (логические px → умножаются на HiDPI scale)
    TARGET_WIDTH_PX   = 160
    PADDING_LEFT_PX   = 16
    PADDING_BOTTOM_PX = -20   # ещё ближе к низу

    BTN_SIZE_PX     = 32
    GAP_PX          = 10
    RADIUS_PX       = 8
    UP_EXTRA_PX     = 1     # минимальный зазор между ↑ и нижним рядом

    # Цвета (RGBA) с общей прозрачностью около 40%
    FILL_RGBA   = [255, 128,   0, 102] # ~40%
    STROKE_RGBA = [255, 128,   0, 140]
    ARROW_RGBA  = [255, 255, 255, 220] # белые стрелки

    if defined?(Sketchup::Overlay)
      class RotateHUDOverlay < Sketchup::Overlay
        def initialize
          super('arlib.hud.overlay', 'AR Library HUD')
          @rep = nil
          @img_w = @img_h = 0
          @png_cap = nil
        end

        # ---------- utils ----------
        def scale(view)
          UI.respond_to?(:scale_factor) ? UI.scale_factor(view) : 1.0
        rescue
          1.0
        end

        def clamp(v, min, max)
          return min if v < min
          return max if v > max
          v
        end

        def ensure_png_loaded
          return false unless File.exist?(HUD::PNG_PATH)
          if @rep.nil?
            begin
              @rep = Sketchup::ImageRep.new(HUD::PNG_PATH)
              @img_w = @rep.width.to_i
              @img_h = @rep.height.to_i
            rescue
              @rep = nil
              @img_w = @img_h = 0
            end
          end
          !@rep.nil? && @img_w > 0 && @img_h > 0
        end

        def png_capabilities(view)
          return @png_cap unless @png_cap.nil?
          @png_cap = { has_draw2d_image: view.respond_to?(:draw2d_image) }
          @png_cap
        end

        def draw_png(view, x0, y0, w, h)
          return false unless ensure_png_loaded
          return false unless png_capabilities(view)[:has_draw2d_image]
          begin
            view.draw2d_image(@rep, Geom::Point3d.new(x0, y0, 0), w, h, 0.0)
            true
          rescue
            false
          end
        end

        # ---------- rounded rect helpers ----------
        def rounded_rect_points(x, y, w, h, r, steps = 6)
          r = [[r, w * 0.5].min, h * 0.5].min
          pts = []
          # четыре угла по часовой (начинаем снизу-слева)
          corner(pts, x + r,     y + r,     r, 180, 270, steps) # bottom-left
          corner(pts, x + w - r, y + r,     r, 270, 360, steps) # bottom-right
          corner(pts, x + w - r, y + h - r, r,   0,  90, steps) # top-right
          corner(pts, x + r,     y + h - r, r,  90, 180, steps) # top-left
          pts
        end

        def corner(arr, cx, cy, r, a0, a1, steps)
          a0_r = a0 * Math::PI / 180.0
          a1_r = a1 * Math::PI / 180.0
          steps.times do |i|
            t = i.to_f / (steps - 1)
            a = a0_r + (a1_r - a0_r) * t
            arr << Geom::Point3d.new(cx + Math.cos(a) * r, cy + Math.sin(a) * r, 0)
          end
        end

        def draw_round_button(view, x, y, size, radius)
          # Заливка
          set_color(view, HUD::FILL_RGBA)
          pts = rounded_rect_points(x, y, size, size, radius)
          view.draw2d(GL_POLYGON, pts)
          # Контур
          set_color(view, HUD::STROKE_RGBA)
          view.draw2d(GL_LINE_STRIP, pts + [pts.first])
        end

        def set_color(view, rgba)
          view.drawing_color = Sketchup::Color.new(*rgba)
        end

        # ---------- arrows ----------
        # draw2d: ось Y вниз — «вверх» = уменьшение Y, «вниз» = увеличение Y.
        def draw_arrow(view, dir, x, y, size)
          set_color(view, HUD::ARROW_RGBA)
          cx = x + size * 0.5
          cy = y + size * 0.5
          r  = size * 0.22 # стрелка чуть меньше

          tri =
            case dir
            when :up
              [
                Geom::Point3d.new(cx,        cy - r, 0),
                Geom::Point3d.new(cx - r,    cy + r, 0),
                Geom::Point3d.new(cx + r,    cy + r, 0)
              ]
            when :down
              [
                Geom::Point3d.new(cx,        cy + r, 0),
                Geom::Point3d.new(cx - r,    cy - r, 0),
                Geom::Point3d.new(cx + r,    cy - r, 0)
              ]
            when :left
              [
                Geom::Point3d.new(cx - r,    cy,     0),
                Geom::Point3d.new(cx + r,    cy + r, 0),
                Geom::Point3d.new(cx + r,    cy - r, 0)
              ]
            when :right
              [
                Geom::Point3d.new(cx + r,    cy,     0),
                Geom::Point3d.new(cx - r,    cy + r, 0),
                Geom::Point3d.new(cx - r,    cy - r, 0)
              ]
            end

          view.draw2d(GL_TRIANGLES, tri)
        end

        # ---------- main draw ----------
        def draw(view)
          s   = scale(view)
          vph = view.vpheight.to_f

          hud_w = HUD::TARGET_WIDTH_PX * s

          png_h = 0.0
          if ensure_png_loaded && @img_w > 0
            png_h = hud_w * @img_h / @img_w.to_f
          end

          btn      = HUD::BTN_SIZE_PX * s
          gap      = HUD::GAP_PX * s
          radius   = HUD::RADIUS_PX * s
          up_extra = HUD::UP_EXTRA_PX * s

          grid_h  = btn * 2 + gap + 12.0 * s
          total_h = (png_h > 0 ? [png_h, grid_h].max : grid_h)

          x0 = HUD::PADDING_LEFT_PX   * s
          y0 = vph - ((HUD::PADDING_BOTTOM_PX * s) + total_h)

          # 1) PNG (если получится)
          draw_png(view, x0, y0, hud_w, png_h) if png_h > 0

          # 2) Векторный слой
          total_w = btn * 3 + gap * 2
          start_x = x0 + clamp((hud_w - total_w) * 0.5, 0.0, hud_w)
          base_y  = y0 + (png_h > 0 ? clamp((png_h - (btn*2 + gap)) * 0.5, 0.0, png_h) : 6 * s)

          # Компоновка: нижний ряд ← ↓ → на base_y; ↑ выше на (btn + gap + up_extra)
          left  = [start_x,                         base_y]
          down  = [start_x + btn + gap,             base_y]
          right = [start_x + 2*btn + 2*gap,         base_y]
          up    = [start_x + btn + gap,             base_y - (btn + gap + up_extra)]

          draw_round_button(view, left[0],  left[1],  btn, radius)
          draw_round_button(view, down[0],  down[1],  btn, radius)
          draw_round_button(view, right[0], right[1], btn, radius)
          draw_round_button(view, up[0],    up[1],    btn, radius)

          draw_arrow(view, :left,  left[0],  left[1],  btn)
          draw_arrow(view, :down,  down[0],  down[1],  btn)
          draw_arrow(view, :right, right[0], right[1], btn)
          draw_arrow(view, :up,    up[0],    up[1],    btn)
        end
      end
    end

    # Публичный API для core (вкл/выкл по фокусу Library)
    def on_dialog_focus(active)
      return unless defined?(Sketchup::Overlay)
      model = Sketchup.active_model
      @overlay ||= RotateHUDOverlay.new
      if active
        begin
          model.overlays.add(@overlay) rescue nil
          @overlay.enabled = true
        rescue
        end
      else
        begin
          @overlay.enabled = false
        rescue
        end
      end
      begin model.active_view.invalidate rescue nil end
    end
  end
end
