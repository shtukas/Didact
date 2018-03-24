#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv('oldname', 'newname')
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'drb/drb'

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# -------------------------------------------------------------------------------------

STREAM_PATH_TO_ITEMS_FOLDER = "/Galaxy/DataBank/Catalyst/Stream"
STREAM_PERFECT_NUMBER = 6

# Stream::itemsFolderpath()
# Stream::getItemDescription(folderpath)
# Stream::pathToItemToCatalystObject(folderpath)
# Stream::objectCommandHandler(object, command)
# Stream::getCatalystObjects()

class Stream

    def self.itemsFolderpath()
        Dir.entries("#{STREAM_PATH_TO_ITEMS_FOLDER}/items")
            .select{|filename| filename[0,1]!='.' }
            .sort
            .map{|filename| "#{STREAM_PATH_TO_ITEMS_FOLDER}/items/#{filename}" }
    end

    def self.getItemDescription(folderpath)
        uuid = IO.read("#{folderpath}/.streamuuid").strip
        description = KeyValueStore::getOrDefaultValue(nil, "c441a43a-bb70-4850-b23c-1db5f5665c9a:#{uuid}", "#{folderpath}")
    end

    def self.pathToItemToCatalystObject(folderpath)
        uuid = IO.read("#{folderpath}/.streamuuid").strip
        description = Stream::getItemDescription(folderpath)
        metric = 0.1 + DRbObject.new(nil, "druby://:10423").metric(uuid, 2, 0.5, 2) # 2 hours per week, base metric=1, run metric=2
        {
            "uuid" => uuid,
            "metric" => metric,
            "announce" => "(#{"%.3f" % metric}) stream: #{description} (#{"%.2f" % ( DRbObject.new(nil, "druby://:10423").getEntityAdaptedTotalTimespan(uuid).to_f/3600 )} hours)",
            "commands" => ["start", "stop", "folder", "completed", "set-description"],
            "default-commands" => DRbObject.new(nil, "druby://:10423").isRunning(uuid) ? ['stop'] : ['start'],
            "command-interpreter" => lambda{|object, command| Stream::objectCommandHandler(object, command) },
            "item-folderpath" => folderpath
        }
    end

    def self.objectCommandHandler(object, command)
        if command=='folder' then
            system("open '#{object['item-folderpath']}'")
            return
        end
        if command=='start' then
            DRbObject.new(nil, "druby://:10423").start(uuid)
            system("open '#{object['item-folderpath']}'")
            return
        end
        if command=='stop' then
            DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
            return
        end
        
        if command=="completed" then
            if DRbObject.new(nil, "druby://:10423").isRunning(object['uuid']) then
                DRbObject.new(nil, "druby://:10423").stopAndAddTimeSpan(uuid)
            end
            timespan = DRbObject.new(nil, "druby://:10423").getEntityAdaptedTotalTimespan(uuid)
            folderpaths = Stream::itemsFolderpath().first(STREAM_PERFECT_NUMBER)
            if folderpaths.size>0 then
                folderpaths.each{|xfolderpath| 
                    next if xfolderpath == object['item-folderpath']
                    xuuid = File.basename(xfolderpath)
                    xtimespan =  timespan.to_f/STREAM_PERFECT_NUMBER
                    puts "Putting #{xtimespan} seconds for #{xuuid}"
                    DRbObject.new(nil, "druby://:10423").addTimeSpan(xuuid, xtimespan)
                }
            end
            time = Time.new
            targetFolder = "/Galaxy/DataBank/Catalyst/ArchivesTimeline/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}/"
            puts "Source: #{object['item-folderpath']}"
            puts "Target: #{targetFolder}"
            FileUtils.mkpath(targetFolder)
            FileUtils.mv("#{object['item-folderpath']}",targetFolder)
            LucilleCore::removeFileSystemLocation(object['item-folderpath'])
            return
        end
        if command=='set-description' then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            uuid = object['uuid']
            KeyValueStore::set(nil, "c441a43a-bb70-4850-b23c-1db5f5665c9a:#{uuid}", "#{description}")
            return
        end
    end

    def self.getCatalystObjects()

        # ---------------------------------------------------
        # DropOff

        Dir.entries("#{STREAM_PATH_TO_ITEMS_FOLDER}/Stream-DropOff")
            .select{|filename| filename[0,1]!='.' }
            .map{|filename| "#{STREAM_PATH_TO_ITEMS_FOLDER}/Stream-DropOff/#{filename}" }
            .each{|filepath|  
                targetfolderpath = "#{STREAM_PATH_TO_ITEMS_FOLDER}/items/#{LucilleCore::timeStringL22()}"
                FileUtils.mkpath(targetfolderpath)
                File.open("#{targetfolderpath}/.streamuuid", 'w'){|f| f.print(SecureRandom.hex(4)) }
                LucilleCore::copyFileSystemLocation(filepath, targetfolderpath)
                LucilleCore::removeFileSystemLocation(filepath)
            }

        # ---------------------------------------------------
        # Catalyst Objects

        answer = []
        folderpaths = Stream::itemsFolderpath()
        loop {
            path = folderpaths.drop(answer.size).first
            break if path.nil?    
            break if answer.size >= STREAM_PERFECT_NUMBER*2
            break if answer.any?{|object| object['metric'] >= 0.2 }
            answer << Stream::pathToItemToCatalystObject(path)        
        }
        answer
    end
end
