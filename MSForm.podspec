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
  MSForm was developed by a student of Control and Automation Engineer that have been working with iOS applications for 2 years.
  Feeling the necessity to have a form in all applications that he worked, this library was build for those who need a form into their application.
  It's easy to setup and you can find out how to do it in the example.
                       DESC

  s.homepage         = 'https://github.com/Cláudio Madureira/MSForm'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Cláudio Madureira' => 'claudiomsilvaf@gmail.com' }
  s.source           = { :git => 'https://github.com/Cláudio Madureira/MSForm.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'MSForm/Classes/**/*'
end
