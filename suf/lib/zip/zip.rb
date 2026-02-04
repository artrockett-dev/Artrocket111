require 'delegate'
require 'singleton'
require 'tempfile'
require 'fileutils'
require 'stringio'
require 'zlib'
require 'rbconfig'

require_relative 'dos_time'
require_relative 'ioextras'
require_relative 'zip_entry'
require_relative 'zip_extra_field'
require_relative 'zip_entry_set'
require_relative 'zip_central_directory'
require_relative 'zip_file'
require_relative 'zip_input_stream'
require_relative 'zip_output_stream'
require_relative 'decompressor'
require_relative 'compressor'
require_relative 'null_decompressor'
require_relative 'null_compressor'
require_relative 'null_input_stream'
require_relative 'pass_thru_compressor'
require_relative 'pass_thru_decompressor'
require_relative 'inflater'
require_relative 'deflater'
require_relative 'zip_streamable_stream'
require_relative 'zip_streamable_directory'
require_relative 'constants'
require_relative 'settings'

if Tempfile.superclass == SimpleDelegator
  require_relative 'tempfile_bugfixed'
  Tempfile = SU_Furniture::BugFix::Tempfile
end

module Zlib  #:nodoc:all
	if !const_defined?(:MAX_WBITS)
		MAX_WBITS = Zlib::Deflate.MAX_WBITS
	end
end
module SU_Furniture
	module Zip
		class ZipError < StandardError ; end
		
		class ZipEntryExistsError            < ZipError; end
		class ZipDestinationFileExistsError  < ZipError; end
		class ZipCompressionMethodError      < ZipError; end
		class ZipEntryNameError              < ZipError; end
		class ZipInternalError               < ZipError; end
	end
end
# Copyright (C) 2002, 2003 Thomas Sondergaard
	# rubyzip is free software; you can redistribute it and/or
	# modify it under the terms of the ruby license.
