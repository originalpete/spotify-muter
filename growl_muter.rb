#!/usr/bin/env macruby

require 'hotcocoa'
include HotCocoa

NORMAL_OUTPUT_DEVICE = "Built-in Output"
DUMMY_OUTPUT_DEVICE = "Soundflower (2ch)"

def set_output_device(device)
  `./SwitchAudioSource -t output -s '#{device}'`
end

def is_ad(desc)
  return true if desc =~ /http\:\/\// || desc =~ /www\..+\.co/ || desc =~ /spotify\:album\:.+/ || desc =~ /Smoke Alarm/ || desc =~/FCO/ || desc =~ /^COI$/ || desc =~ /Travel Filler/
  false
end

mute = false
ad = false
semaphore = Mutex.new

application do
  on_notification :distributed=>true, :named=> 'GrowlNotificationRebroadcast', :when_suspended=>:coalesce do |note|
    
    if note.userInfo["ApplicationName"] == "Spotify" && note.userInfo["NotificationName"] == "Currently playing track"
      
      # wrap the logic in a mutex otherwise two simultaneous notifications could put 
      # the volume and mute variables into inconsistent state.
      semaphore.synchronize {
        
        puts "\n\n--------------------------------------"
        
        puts "name: #{note.name}"
        puts "app: #{note.userInfo["ApplicationName"]}"
        puts "note name: #{note.userInfo["NotificationName"]}"
        puts "note title: #{note.userInfo["NotificationTitle"]}"
        puts "note desc: #{note.userInfo["NotificationDescription"]}"
        
        ad = is_ad(note.userInfo["NotificationDescription"])
        
        if ad && !mute
          puts "ad detected, switching sound device"
          set_output_device(DUMMY_OUTPUT_DEVICE)
          mute = true
          
        elsif ad && mute
          puts "ad detected, already on dummy sound device, doing nothing"
          
        elsif !ad && mute
          puts "track doesn't look like an ad, switching back to default device"
          set_output_device(NORMAL_OUTPUT_DEVICE)
          mute = false
        
        elsif !ad && !mute
          puts "not an ad, not mute, doing nothing"
        end
      }
      
    end
    
  end
end
