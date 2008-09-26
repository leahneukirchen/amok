# Rakefile for Amok.  -*-ruby-*-
require 'rake/rdoctask'
require 'rake/testtask'


desc "Run all the tests"
task :default => [:test]

desc "Do predistribution stuff"
task :predist => [:chmod, :changelog, :rdoc]


desc "Make an archive as .tar.gz"
task :dist => [:fulltest, :predist] do
  sh "git archive --format=tar --prefix=#{release}/ HEAD^{tree} >#{release}.tar"
  sh "pax -waf #{release}.tar -s ':^:#{release}/:' RDOX SPEC ChangeLog doc"
  sh "gzip -f -9 #{release}.tar"
end

# Helper to retrieve the "revision number" of the git tree.
def git_tree_version
  if File.directory?(".git")
    @tree_version ||= `git describe`.strip.sub('-', '.')
    @tree_version = "0.1"  if @tree_version.empty?
    @tree_version << ".0"  unless @tree_version.count('.') == 2
  else
    $: << "lib"
    require 'amok'
    @tree_version = Amok::VERSION
  end
  @tree_version
end

def gem_version
  git_tree_version.gsub(/-.*/, '')
end

def release
  "rack-#{git_tree_version}"
end

def manifest
  `git ls-files`.split("\n")
end


desc "Make binaries executable"
task :chmod do
  Dir["bin/*"].each { |binary| File.chmod(0775, binary) }
  Dir["test/cgi/test*"].each { |binary| File.chmod(0775, binary) }
end

desc "Generate a ChangeLog"
task :changelog do
  File.open("ChangeLog", "w") { |out|
    `git log -z`.split("\0").map { |chunk|
      author = chunk[/Author: (.*)/, 1].strip
      date = chunk[/Date: (.*)/, 1].strip
      desc, detail = $'.strip.split("\n", 2)
      detail ||= ""
      detail = detail.gsub(/.*darcs-hash:.*/, '')
      detail.rstrip!
      out.puts "#{date}  #{author}"
      out.puts "  * #{desc.strip}"
      out.puts detail  unless detail.empty?
      out.puts
    }
  }
end


desc "Generate RDox"
task "RDOX" do
  sh "bacon -Ilib --automatic --specdox >RDOX"
end

desc "Run all the tests"
task :test do
  sh "bacon -Ilib --automatic --quiet"
end


begin
  $" << "sources"  if defined? FromSrc
  require 'rubygems'

  require 'rake'
  require 'rake/clean'
  require 'rake/packagetask'
  require 'rake/gempackagetask'
  require 'fileutils'
rescue LoadError
  # Too bad.
else
  spec = Gem::Specification.new do |s|
    s.name            = "amok"
    s.version         = gem_version
    s.platform        = Gem::Platform::RUBY
    s.summary         = "a compact mock library"

    s.description = <<-EOF
Amok is a compact mock library.

http://github.com/chneukirchen/amok
    EOF

    s.files           = manifest + %w(RDOX)
    s.require_path    = 'lib'
    s.has_rdoc        = true
    s.extra_rdoc_files = ['README', 'RDOX']
    s.test_files      = []

    s.author          = 'Christian Neukirchen'
    s.email           = 'chneukirchen@gmail.com'
    s.homepage        = 'http://github.com/chneukirchen/amok'
  end

  Rake::GemPackageTask.new(spec) do |p|
    p.gem_spec = spec
    p.need_tar = false
    p.need_zip = false
  end
end

desc "Generate RDoc documentation"
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.options << '--line-numbers' << '--inline-source' <<
    '--main' << 'README' <<
    '--title' << 'Amok Documentation' <<
    '--charset' << 'utf-8'
  rdoc.rdoc_dir = "doc"
  rdoc.rdoc_files.include 'README'
  rdoc.rdoc_files.include 'COPYING'
  rdoc.rdoc_files.include 'RDOX'
  rdoc.rdoc_files.include('lib/amok.rb')
end
task :rdoc => ["RDOX"]
