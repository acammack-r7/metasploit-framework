#!/usr/bin/env ruby

# Run an external module in isolation

# TODO require 'optparse'

module Msf
  module Modules
  end
end

msfbase = __FILE__
while File.symlink?(msfbase)
  msfbase = File.expand_path(File.readlink(msfbase), File.dirname(msfbase))
end

$:.unshift(File.expand_path(File.join(File.dirname(msfbase), '..', '..', 'lib')))
require 'msf/core/modules/external/bridge'

def load_module
  module_path = ARGV[0]
  mod = Msf::Modules::External::Bridge.open(module_path)
end

def usage(mod='MODULE_FILE', name='Run a module outside of Metasploit Framework')
  $stderr.puts "Usage: solo #{mod} [OPTION=VALUE]"
  $stderr.puts name
  $stderr.puts
  $stderr.puts 
end

def module_usage
  mod = load_module
  usage(mod.path, mod.meta['name'])
  $stderr.puts

  mod.meta['options'].each do |n, o|
    $stderr.puts "  #{n}: #{o['description']} (#{o['default']}) #{'required' if o['required']}"
  end
end

def run_module
  mod = load_module
  mod.run parse_args
  wait_status(mod)
end

def parse_args
  args = ARGV[1..-1]

  os = load_module().meta['options']
  defaults = os.map {|n, o| [n, o['default']]}.to_h

  x = args.map do |a|
    a.split('=', 2)
  end.to_h

  defaults.merge(x)
end

def wait_status(mod)
  begin
    while mod.running
      m = mod.get_status
      if m
        case m.method
        when :message
          log_output(m)
        when :report
          process_report(m)
        when :reply
          # we're done
          break
        end
      end
    end
  rescue Interrupt => e
    raise e
  rescue Exception => e
    elog e.backtrace.join("\n")
    fail_with Msf::Module::Failure::Unknown, e.message
  end
end

def process_report(m)

end

def log_output(m)
  message = m.params['message']

  case m.params['level']
  when 'error'
    puts "error:  #{message}"
  when 'warning'
    puts "warning:  #{message}"
  when 'good'
    puts "good:  #{message}"
  when 'info'
    puts message
  when 'debug'
    nil # skip for now
    #puts "debug:  #{m['message']}"
  else
    puts message
  end
end

if ARGV.empty? || ARGV.first[0] == '-'
  useage
elsif ARGV.length == 1 || ARGV[1] == '-h' || ARGV[1] == '--help' || ARGV[1] == '-?'
  module_usage
else
  run_module
end
