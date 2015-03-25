# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require 'securerandom'

include Java

class LogStash::Filters::Java < LogStash::Filters::Base
  config_name "java"

  milestone 1

  config :code, :validate => :string, :required => true
  config :classpath, :validate => :string, :required => false

  public
  def register
    basePath = File.dirname(File.expand_path(__FILE__))
    templateFile = File.join(basePath, "Template.java")
    template = File.read(templateFile)

    codeFile = eval("\"" + template + "\"")

    compilation_path = basePath + '/../../../temp/' + SecureRandom.hex + '/'
    Dir.mkdir(compilation_path) unless File.exists?(compilation_path)
    compilation_path = File.realpath(compilation_path)

    filePath = compilation_path + '/FilterClass.java'
    File.write(filePath, codeFile)
    classpath = "." if classpath.nil? || classpath.empty?
    compilationCommand = "javac -cp #{classpath} #{filePath}"
    puts compilationCommand
    puts `#{compilationCommand} 2>&1 `

    $CLASSPATH << compilation_path
    $CLASSPATH << classpath
    @myClass = JavaUtilities.get_proxy_class('FilterClass')
  end

  public
  def filter(event)
    # return nothing unless there's an actual filter event
    return unless filter?(event)

    if !@myClass.Process(event.to_hash)
      event.cancel
    end

    filter_matched(event)
  end
end
