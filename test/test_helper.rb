require 'test/unit'
require 'fileutils'
require 'find'

unless defined?(TEST_DIR)
	TEST_DIR = File.dirname(__FILE__)
end
require TEST_DIR + '/../lib/scm'

Scm::Adapters::AbstractAdapter.logger = Logger.new(File.open('log/test.log','a'))

unless defined?(REPO_DIR)
	REPO_DIR = File.expand_path(File.join(TEST_DIR, 'repositories'))
end

unless defined?(DATA_DIR)
	DATA_DIR = File.expand_path(File.join(TEST_DIR, 'data'))
end

class Scm::Test < Test::Unit::TestCase
	# For reasons unknown, the base class defines a default_test method to throw a failure.
	# We override it with a no-op to prevent this 'helpful' feature.
	def default_test
	end

	def assert_convert(parser, log, expected)
		result = ''
		parser.parse File.new(log), :writer => Scm::Parsers::XmlWriter.new(result)
		assert_buffers_equal File.read(expected), result
	end

	# assert_equal just dumps the massive strings to the console, which is not helpful.
	# Instead we try to indentify the line of the first error.
	def assert_buffers_equal(expected, actual)
		return if expected == actual

		expected_lines = expected.split("\n")
		actual_lines = actual.split("\n")

		expected_lines.each_with_index do |line, i|
			if line != actual_lines[i]
				assert_equal line, actual_lines[i], "at line #{i} of the reference buffer"
			end
		end

		# We couldnt' find the mismatch. Just bail.
		assert_equal expected_lines, actual_lines
	end

	def with_repository(type, name, block)
		Scm::ScratchDir.new do |dir|
			if Dir.entries(REPO_DIR).include?(name)
				`cp -R #{File.join(REPO_DIR, name)} #{dir}`
			elsif Dir.entries(REPO_DIR).include?(name + '.tgz')
				`tar xzf #{File.join(REPO_DIR, name + '.tgz')} --directory #{dir}`
			else
				raise RuntimeError.new("Repository archive #{File.join(REPO_DIR, name)} not found.")
			end
			block.call(type.new(:url => File.join(dir, name)).normalize)
		end
	end

	def with_svn_repository(name, &block)
		with_repository(Scm::Adapters::SvnAdapter, name, block)
	end

	def with_cvs_repository(name, &block)
		with_repository(Scm::Adapters::CvsAdapter, name, block)
	end

	def with_git_repository(name, &block)
		with_repository(Scm::Adapters::GitAdapter, name, block)
	end

	def with_hg_repository(name, &block)
		with_repository(Scm::Adapters::HgAdapter, name, block)
	end

	def with_bzr_repository(name, &block)
		with_repository(Scm::Adapters::BzrAdapter, name, block)
	end
end
