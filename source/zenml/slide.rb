# coding: utf-8


module Zenithal::Slide

  VERSION = "1.0.0"
  VERSION_ARRAY = VERSION.split(/\./).map(&:to_i)

end


require 'fileutils'
require 'open3'
require 'rexml/document'
require 'selenium-webdriver'

require_relative 'slide/converter'