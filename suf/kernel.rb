# Fix require_relative for SketchUp (.rbe/.rbs), keeping it in Kernel and
# resolving paths relative to the *caller* file, just like Ruby does.

module Kernel
  # Save original once, if not already saved (avoid double aliasing on reloads)
  unless method_defined?(:__orig_require_relative)
    alias_method :__orig_require_relative, :require_relative
    private :__orig_require_relative
  end

  private def require_relative(path)
    # 1) Try the native way (works for plain .rb during development)
    begin
      return __orig_require_relative(path)
    rescue LoadError, TypeError
      # Fall through to SketchUp fallback
    end

    # 2) SketchUp fallback for encrypted/compiled files (.rbe/.rbs)
    #    Determine the caller's file dir so resolution matches Ruby semantics.
    loc = caller_locations(1, 1)&.first
    caller_file =
      (loc.respond_to?(:absolute_path) && loc.absolute_path) ||
      (loc && loc.path)

    # If we fail to get a caller file (console, eval, etc.), use $0 as a last resort.
    caller_file ||= (defined?($0) && $0) || __FILE__
    base_dir = File.dirname(caller_file)

    # Build absolute feature path without forcing an extension.
    feature = File.expand_path(path, base_dir)

    # Only attempt SketchUp fallback if available.
    if defined?(Sketchup) && Sketchup.respond_to?(:require)
      begin
        return Sketchup.require(feature)
      rescue LoadError => e
        # If SketchUp also fails, raise a clean error consistent with Ruby behavior.
        raise LoadError, "cannot load such file -- #{path} (resolved: #{feature}): #{e.message}"
      end
    else
      # Not in SketchUp or no Sketchup.require – re-raise like original.
      raise LoadError, "cannot load such file -- #{path} (resolved: #{feature})"
    end
  end
end
