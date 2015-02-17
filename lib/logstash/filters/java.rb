# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

include Java

class LogStash::Filters::Java < LogStash::Filters::Base
  config_name "java"

  milestone 1

  config :code, :validate => :string, :required => true

  public
  def register
    templatePath = File.dirname(File.expand_path(__FILE__))
    templateFile = File.join(templatePath, "Template.java")
    template = File.read(templateFile)

    codeFile = eval("\"" + template + "\"")

    filePath = 'temp/FilterClass.java'
    File.write(filePath, codeFile)
    system("javac #{filePath}")

    $CLASSPATH << File.join(Dir.pwd, 'temp')
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
