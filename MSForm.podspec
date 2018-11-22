#
# Be sure to run `pod lib lint MSForm.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MSForm'
  s.version          = '0.1.0'
  s.summary          = 'MSForm is a library for those who need to build a form into their application in a simple way.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Based on the necessity to have a form in basically all applications, this library was built for those who need a form. It's easy to setup and you can find out how to do it in the example.
                       DESC

  s.homepage         = 'https://github.com/claudiomadureira/MSForm'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Cláudio Madureira' => 'claudiomsilvaf@gmail.com' }
  s.source           = { :git => 'https://github.com/claudiomadureira/MSForm.git', :tag => s.version.to_s }
  s.swift_version	 = '4.2'
  s.ios.deployment_target = '8.0'

  s.source_files = 'MSForm/Classes/**/*'
end
