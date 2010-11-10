module Guard
  class Spork
    class Runner
      attr_accessor :options
      
      def initialize(options = {})
        options[:rspec_port] ||= 8989
        options[:cucumber_port] ||= 8990
        @options = options
      end
      
      def launch_sporks(action)
        UI.info "#{action.capitalize}ing Spork for #{sporked_gems} ", :reset => true
        system(spork_command("rspec")) if rspec?
        system(spork_command("cucumber")) if cucumber?
        verify_launches(action)
      end
      
      def kill_sporks
        system("kill $(ps aux | awk '/spork/&&!/awk/{print $2;}') >/dev/null 2>&1")
      end
      
    private
      
      def spork_command(type)
        cmd_parts = []
        cmd_parts << "bundle exec" if bundler?
        cmd_parts << "spork"
        
        case type
        when "rspec"
          cmd_parts << "-p #{options[:rspec_port]}"
        when "cucumber"
          cmd_parts << "cu"
          cmd_parts << "-p #{options[:cucumber_port]}"
        end
        
        cmd_parts << ">/dev/null 2>&1 < /dev/null &"
        cmd_parts.join(" ")
      end
      
      def verify_launches(action)
        30.times do
          sleep 1
          begin
            TCPSocket.new('localhost', options[:rspec_port]).close if rspec?
            TCPSocket.new('localhost', options[:cucumber_port]).close if cucumber?
          rescue Errno::ECONNREFUSED
            print '.'
            next
          end
          UI.info "Spork for #{sporked_gems} successufly #{action}ed", :reset => true
          Notifier.notify "#{sporked_gems} successufly #{action}ed", :title => "Spork", :image => :success
          return true
        end
        UI.error "Could not #{action} Spork for #{sporked_gems}. Make sure you can use it manually first.", :reset => true
        Notifier.notify "#{sporked_gems} NOT #{action}ed", :title => "Spork", :image => :failed
      end
      
      def sporked_gems
        gems = []
        gems << "RSpec" if rspec?
        gems << "Cucumber" if cucumber?
        gems.join(' & ')
      end
      
      def bundler?
        @bundler ||= File.exist?("#{Dir.pwd}/Gemfile") && options[:bundler] != false
      end
      
      def rspec?
        @rspec ||= File.exist?("#{Dir.pwd}/spec") && options[:rspec] != false
      end
      
      def cucumber?
        @cucumber ||= File.exist?("#{Dir.pwd}/features") && options[:cucumber] != false
      end
      
    end
  end
end