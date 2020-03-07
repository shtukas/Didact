#!/usr/bin/ruby

# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'colorize'
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'time'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'find'
require 'drb/drb'
require 'thread'

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/YmirEstate.rb"

# --------------------------------------------------------------------

require_relative "BinUtils.rb"

PATH_TO_YMIR = "/Users/pascal/Galaxy/Orbital/Ymir"
TODO_INBOX_TIMELINE_NAME = "[Inbox]"

class Utils

    # Utils::chooseALinePecoStyle(announce: String, strs: Array[String]): String
    def self.chooseALinePecoStyle(announce, strs)
        `echo "#{strs.join("\n")}" | peco --prompt "#{announce}"`.strip
    end

    # Utils::l22()
    def self.l22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Utils::editTextUsingTextmate(text)
    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end
end

class Estate

    # Estate::getTNodesEnumerator(pathToYmir, collection)
    def self.getTNodesEnumerator(pathToYmir, collection)
        isFilenameOfTNode = lambda {|filename|
            filename[-5, 5] == ".json"
        }
        Enumerator.new do |tnodes|
            YmirEstate::ymirFilepathEnumerator(pathToYmir, collection).each{|filepath|
                next if !isFilenameOfTNode.call(File.basename(filepath))
                tnodes << JSON.parse(IO.read(filepath))
            }
        end
    end

    # Estate::tnodeEnumerator()
    def self.tnodeEnumerator()
        Estate::getTNodesEnumerator(PATH_TO_YMIR, "todo")
    end

    # Estate::tNodeFilenameToFilepathOrNull(filename)
    def self.tNodeFilenameToFilepathOrNull(filename)
        YmirEstate::ymirFilepathEnumerator(PATH_TO_YMIR, "todo").each{|filepath|
            return filepath if ( File.basename(filepath) == filename )
        }
        nil
    end

    # Estate::getTNodeByUUUIDOrNull(uuid)
    def self.getTNodeByUUUIDOrNull(uuid)
        Estate::getTNodesEnumerator(PATH_TO_YMIR, "todo").each{|tnode|
            return tnode if ( tnode["uuid"] == uuid )
        }
        nil
    end

    # Estate::uniqueNameResolutionLocationPathOrNull(uniquename)
    def self.uniqueNameResolutionLocationPathOrNull(uniquename)
        location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
        return nil if location.nil?
        location
    end

    # Estate::commitTNodeToDisk(tnode)
    def self.commitTNodeToDisk(tnode)
        filepath = Estate::tNodeFilenameToFilepathOrNull(tnode["filename"])
        if filepath.nil? then
            filepath = YmirEstate::makeNewYmirLocationForBasename(PATH_TO_YMIR, "todo", tnode["filename"])
        end
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(tnode)) }
    end

    # Estate::destroyTNode(tnode)
    def self.destroyTNode(tnode)
        # We try and preserve contents

        destroyTarget = lambda{|target|
            if target["type"] == "line-2A35BA23" then
                # Nothing
                return
            end
            if target["type"] == "text-A9C3641C" then
                textFilepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, "todo", target["filename"])
                return if textFilepath.nil?
                return if !File.exists?(textFilepath)
                CatalystCommon::copyLocationToCatalystBin(textFilepath)
                LucilleCore::removeFileSystemLocation(textFilepath)
                return
            end
            if target["type"] == "url-01EFB604" then
                # Nothing
                return
            end
            if target["type"] == "unique-name-11C4192E" then
                # Nothing
                return
            end
            if target["type"] == "perma-dir-AAD08D8B" then
                folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, "todo", target["foldername"])
                return if folderpath.nil?
                return if !File.exists?(folderpath)
                CatalystCommon::copyLocationToCatalystBin(folderpath)
                LucilleCore::removeFileSystemLocation(folderpath)
                return
            end
            raise "[error: e838105]"
        }

        destroyClassificationItem = lambda{|item|
            if item["type"] == "tag-8ACC01B9" then
                # Nothing
                return
            end
            if item["type"] == "timeline-49D07018" then
                # Nothing
                return
            end
            raise "[error: a38375c2]"
        }

        tnode["targets"].each{|target| destroyTarget.call(target) }
        tnode["classification"].each{|item| destroyClassificationItem.call(item) }

        tnodelocation = Estate::tNodeFilenameToFilepathOrNull(tnode["filename"])
        if tnodelocation.nil? then
            puts "[warning: 82d400d0] Interesting. This should not have hapenned."
            LucilleCore::pressEnterToContinue()
            return
        end
        CatalystCommon::copyLocationToCatalystBin(tnodelocation)
        LucilleCore::removeFileSystemLocation(tnodelocation)
    end

end

class CoreData

    # CoreData::timelines()
    def self.timelines()
        Estate::tnodeEnumerator()
            .map{|tnode| tnode["classification"] }
            .flatten
            .select{|item| item["type"] == "timeline-49D07018" }
            .map{|item| item["timeline"] }
            .uniq
    end

    # CoreData::timelinesInIncreasingActivityTime()
    def self.timelinesInIncreasingActivityTime()
        extractTimelinesFromTNode = lambda {|tnode|
            tnode["classification"]
                .select{|item| item["type"] == "timeline-49D07018" }
                .map{|item| item["timeline"] }
        }
        map1 = Estate::tnodeEnumerator().reduce({}){|map2, tnode|
            timelines = extractTimelinesFromTNode.call(tnode)
            timelines.each{|timeline|
                if map2[timeline].nil? then
                    map2[timeline] = tnode["creationTimestamp"]
                else
                    map2[timeline] = [map2[timeline], tnode["creationTimestamp"]].max
                end
            }
            map2
        }
        map1
            .to_a
            .sort{|p1, p2| p1[1]<=>p2[1] }
            .map{|pair| pair[0] }
    end

    # CoreData::tNodeIsOnThisTimeline(tnode, timeline)
    def self.tNodeIsOnThisTimeline(tnode, timeline)
        tnode["classification"].any?{|item| item["type"] == "timeline-49D07018" and item["timeline"] == timeline }
    end

    # CoreData::getTimelineTNodesOrdered(timeline)
    def self.getTimelineTNodesOrdered(timeline)
        Estate::tnodeEnumerator()
            .select{|tnode| CoreData::tNodeIsOnThisTimeline(tnode, timeline) }
            .sort{|tn1, tn2| tn1["creationTimestamp"] <=> tn2["creationTimestamp"] }
    end

    # CoreData::searchPatternToTNodes(pattern)
    def self.searchPatternToTNodes(pattern)
        Estate::tnodeEnumerator()
            .select{|tnode| tnode["description"].downcase.include?(pattern.downcase) }
            .sort{|tn1, tn2| tn1["creationTimestamp"] <=> tn2["creationTimestamp"] }
    end
end

class TMakers

    # TMakers::interactivelymakeZeroOrMoreTags()
    def self.interactivelymakeZeroOrMoreTags()
        tags = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty for exit): ")
            break if tag.size == 0
            tags << tag
        }
        tags
    end

    # TMakers::interactivelySelectTimelineOrNull()
    def self.interactivelySelectTimelineOrNull()
        timeline = Utils::chooseALinePecoStyle("Timeline:", [""] + CoreData::timelinesInIncreasingActivityTime().reverse)
        return nil if timeline.size == 0
        timeline
    end

    # TMakers::interactivelySelectAtLeastOneTimelinePossiblyNewOne()
    def self.interactivelySelectAtLeastOneTimelinePossiblyNewOne()
        timelines = []
        loop {
            timeline = TMakers::interactivelySelectTimelineOrNull()
            break if timeline.nil?
            timelines << timeline
        }
        loop {
            timeline = LucilleCore::askQuestionAnswerAsString("new timeline (empty to exit): ")
            break if timeline.size == 0
            timelines << timeline
        }
        if timelines.size == 0 then
            return TMakers::interactivelySelectAtLeastOneTimelinePossiblyNewOne()
        end
        timelines
    end

    # TMakers::makeTNodeTargetInteractivelyOrNull()
    def self.makeTNodeTargetInteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "text", "url", "unique name", "permadir"])
        return nil if type.nil?
        if type == "line" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "line-2A35BA23",
                "line" => LucilleCore::askQuestionAnswerAsString("line: ")
            }
        end
        if type == "text" then
            filename = "#{Utils::l22()}.txt"
            filecontents = Utils::editTextUsingTextmate("")
            filepath = YmirEstate::makeNewYmirLocationForBasename(PATH_TO_YMIR, "todo", filename)
            File.open(filepath, "w"){|f| f.puts(filecontents) }
            return {
                "uuid"     => SecureRandom.uuid,
                "type"     => "text-A9C3641C",
                "filename" => filename
            }
        end
        if type == "url" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "url-01EFB604",
                "url"  => LucilleCore::askQuestionAnswerAsString("url: ")
            }
        end
        if type == "unique name" then
            return {
                "uuid" => SecureRandom.uuid,
                "type" => "unique-name-11C4192E",
                "name" => LucilleCore::askQuestionAnswerAsString("unique name: ")
            }
        end
        if type == "permadir" then
            foldername = Utils::l22()
            folderpath = YmirEstate::makeNewYmirLocationForBasename(PATH_TO_YMIR, "todo", foldername)
            FileUtils.mkdir(folderpath)
            system("open '#{folderpath}'")
            return {
                "uuid"       => SecureRandom.uuid,
                "type"       => "perma-dir-AAD08D8B",
                "foldername" => foldername
            }
        end
    end

    # TMakers::makeTNodeTargetsAtLeastOne()
    def self.makeTNodeTargetsAtLeastOne()
        targets = []
        while targets.size == 0 do
            targets << TMakers::makeTNodeTargetInteractivelyOrNull()
            targets = targets.compact
        end
        loop {
            if LucilleCore::askQuestionAnswerAsBoolean("Another target? ") then
                targets << TMakers::makeTNodeTargetInteractivelyOrNull()
                targets = targets.compact
            else
                break
            end
        }
        targets
    end

    # TMakers::makeNewTNode()
    def self.makeNewTNode()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        targets = TMakers::makeTNodeTargetsAtLeastOne()
        classificationItems1 = TMakers::interactivelySelectAtLeastOneTimelinePossiblyNewOne()
                                    .map{|timeline|
                                        {
                                            "uuid"     => SecureRandom.uuid,
                                            "type"     => "timeline-49D07018",
                                            "timeline" => timeline
                                        }
                                    }
        classificationItems2 = TMakers::interactivelymakeZeroOrMoreTags()
                                    .map{|tag|
                                        {
                                            "uuid" => SecureRandom.uuid,
                                            "type" => "tag-8ACC01B9",
                                            "tag"  => tag
                                        }
                                    }
        tnode = {
            "uuid"              => uuid,
            "filename"          => "#{Utils::l22()}.json",
            "creationTimestamp" => Time.new.to_f,
            "description"       => description,
            "targets"           => targets,
            "classification"    => classificationItems1 + classificationItems2
        }
        puts JSON.pretty_generate(tnode)
        Estate::commitTNodeToDisk(tnode)
    end

    # TMakers::mutateTNodeRemoveThisTimeline(tnode, timeline)
    def self.mutateTNodeRemoveThisTimeline(tnode, timeline)
        tnode["classification"] = tnode["classification"]
                                        .map{|item|
                                            if item["type"] == "timeline-49D07018" then 
                                                if item["timeline"] == timeline then
                                                    nil
                                                else
                                                    item
                                                end
                                            else
                                                item
                                            end
                                        }.compact
        tnode
    end

end

class Interface

    # Interface::targetToString(target)
    def self.targetToString(target)
        if target["type"] == "line-2A35BA23" then
            return "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, "todo", target["filename"])
            if filepath.nil? or !File.exists?(filepath) then
                return "[error: e8703185] There doesn't seem to be a Ymir file for filename '#{target["filename"]}'"
            else
                return "text (#{IO.read(filepath).lines.count} lines)"
            end
        end
        if target["type"] == "url-01EFB604" then
            return "url: #{target["url"]}"
        end
        if target["type"] == "unique-name-11C4192E" then
            return "unique name: #{target["name"]}"
        end
        if target["type"] == "perma-dir-AAD08D8B" then
            return "foldername: #{target["foldername"]}"
        end
        raise "[error: 706ce2f5]"
    end

    # Interface::classificationItemToString(item)
    def self.classificationItemToString(item)
        if item["type"] == "tag-8ACC01B9" then
            return "tag: #{item["tag"]}"
        end
        if item["type"] == "timeline-49D07018" then
            return "timeline: #{item["timeline"]}"
        end
        raise "[error: 44ccb03c]"
    end

    # Interface::diveTarget(tnodeuuid, target)
    def self.diveTarget(tnodeuuid, target)
        puts "Target: #{Interface::targetToString(target)}"
        operations = [
            "open", 
            "remove/destroy from tnode"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation: ", operations)
        return if operation.nil?
        if operation == "open" then

        end
        if operation == "remove/destroy from tnode" then
            # we get the tnode and just remove the offending target
            tnode = Estate::getTNodeByUUUIDOrNull(tnodeuuid)
            return if tnode.nil?
            tnode["targets"] = tnode["targets"].reject{|t| t["uuid"]==target["uuid"] }
            Estate::commitTNodeToDisk(tnode)
        end
    end

    # Interface::diveClassificationItem(tnodeuuid, item)
    def self.diveClassificationItem(tnodeuuid, item)
        puts "Item: #{Interface::classificationItemToString(item)}"
        operations = [
            "remove/destroy from tnode"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation: ", operations)
        return if operation.nil?
        if operation == "remove/destroy from tnode" then
            # we get the tnode and just remove the offending classification item
            tnode = Estate::getTNodeByUUUIDOrNull(tnodeuuid)
            return if tnode.nil?
            tnode["classification"] = tnode["classification"].reject{|i| i["uuid"]==item["uuid"] }
            Estate::commitTNodeToDisk(tnode)
        end
    end

    # Interface::diveTargets(tnodeuuid, targets)
    def self.diveTargets(tnodeuuid, targets)
        target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target: ", targets, lambda{|target| Interface::targetToString(target) })
        return if target.nil?
    end

    # Interface::diveClassificationItems(tnodeuuid, items)
    def self.diveClassificationItems(tnodeuuid, items)
        puts "Interface::diveClassificationItems is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # Interface::openTarget(target)
    def self.openTarget(target)
        if target["type"] == "line-2A35BA23" then
            puts "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, "todo", target["filename"])
            if filepath.nil? or !File.exists?(filepath) then
                puts "[error: 359a6c99] There doesn't seem to be a Ymir file for filename '#{target["filename"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{filepath}'")
        end
        if target["type"] == "url-01EFB604" then
            system("open '#{target["url"]}'")
        end
        if target["type"] == "unique-name-11C4192E" then
            uniquename = target["name"]
            location = Estate::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location.nil? then
                puts "I could not resolve unique name '#{uniquename}'"
                LucilleCore::pressEnterToContinue()
            else
                if LucilleCore::askQuestionAnswerAsBoolean("opening '#{location}' ? ") then
                    system("open '#{location}'")
                end
            end
        end
        if target["type"] == "perma-dir-AAD08D8B" then
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, "todo", target["foldername"])
            if folderpath.nil? or !File.exists?(folderpath) then
                puts "[error: c87c7b41] There doesn't seem to be a Ymir file for filename '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{folderpath}'")
        end
    end

    # Interface::optimizedOpenTarget(target)
    def self.optimizedOpenTarget(target)
        if target["type"] == "line-2A35BA23" then
            puts "line: #{target["line"]}"
        end
        if target["type"] == "text-A9C3641C" then
            filepath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, "todo", target["filename"])
            if filepath.nil? or !File.exists?(filepath) then
                puts "[error: a3a1b7a0] There doesn't seem to be a Ymir file for filename '#{target["filename"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            system("open '#{filepath}'")
        end
        if target["type"] == "url-01EFB604" then
            system("open '#{target["url"]}'")
        end
        if target["type"] == "unique-name-11C4192E" then
            uniquename = target["name"]
            location = Estate::uniqueNameResolutionLocationPathOrNull(uniquename)
            if location.nil? then
                puts "I could not resolve unique name '#{uniquename}'"
                LucilleCore::pressEnterToContinue()
            else
                system("open '#{location}'")
            end
        end
        if target["type"] == "perma-dir-AAD08D8B" then
            locationCanBeQuickOpened = lambda {|location|
                # We white list the ones that we want
                whiteListedExtensions = [".txt", ".jpg", ".png", ".md", ".webloc", ".eml"]
                return true if whiteListedExtensions.any?{|extension| location[-extension.size, extension.size] == extension }
                false
            }
            folderpath = YmirEstate::locationBasenameToYmirLocationOrNull(PATH_TO_YMIR, "todo", target["foldername"])
            if folderpath.nil? or !File.exists?(folderpath) then
                puts "[error: 0916fd87] There doesn't seem to be a Ymir file for filename '#{target["foldername"]}'"
                LucilleCore::pressEnterToContinue()
                return
            end
            sublocations = LucilleCore::nonDottedLocationsAtFolder(folderpath)
            if sublocations.size != 0 and locationCanBeQuickOpened.call(sublocations[0]) and !sublocations[0].include?("'") then
                system("open '#{sublocations[0]}'")
            else
                system("open '#{folderpath}'")
            end
        end
    end

    # Interface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
    def self.optimizedOpenTNodeUniqueTargetOrNothing(tnode)
        return if tnode["targets"].size != 1
        Interface::optimizedOpenTarget(tnode["targets"][0])
    end

    # Interface::tNodeDive(tnodeuuid)
    def self.tNodeDive(tnodeuuid)
        loop {
            tnode = Estate::getTNodeByUUUIDOrNull(tnodeuuid)
            if tnode.nil? then
                raise "[error: a151f422] tnodeuuid: #{tnodeuuid}"
            end
            puts "tnode:"
            puts "    uuid: #{tnode["uuid"]}"
            puts "    filename: #{tnode["filename"]}"
            puts "    description: #{tnode["description"]}"
            puts "    targets:"
            tnode["targets"].each{|target|
                puts "        #{Interface::targetToString(target)}"
            }
            puts "    classification items:"
            tnode["classification"].each{|item|
                puts "        #{Interface::classificationItemToString(item)}"
            }
            operations = [
                "quick open",
                "edit description",
                "dive targets",
                "dive classification items",
                "destroy tnode"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "quick open" then
                Interface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
            end
            if operation == "edit description" then
                tnode["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
                Estate::commitTNodeToDisk(tnode)
            end
            if operation == "dive targets" then
                Interface::diveTargets(tnode["uuid"], tnode["targets"])
            end
            if operation == "dive classification items" then
                Interface::diveClassificationItems(tnode["uuid"], tnode["classification"])
            end
            if operation == "destroy tnode" then
                if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item? ") then
                    Estate::destroyTNode(tnode)
                    return
                end
            end
        }
    end

    # Interface::tNodesDive(tnodes)
    def self.tNodesDive(tnodes)
        loop {
            tnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("tnode: ", tnodes, lambda{|tnode| tnode["description"] })
            return if tnode.nil?
            Interface::tNodeDive(tnode["uuid"])
        }
    end

    # Interface::timelineDive(timeline)
    def self.timelineDive(timeline)
        loop {
            puts "Timeline: #{timeline}"
            tnodes = CoreData::getTimelineTNodesOrdered(timeline)
            tnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("tnode: ", tnodes, lambda{|tnode| tnode["description"] })
            return if tnode.nil?
            Interface::tNodeDive(tnode["uuid"])
        }
    end

    # Interface::timelinesDive()
    def self.timelinesDive()
        loop {
            timeline = TMakers::interactivelySelectTimelineOrNull()
            return if timeline.nil?
            Interface::timelineDive(timeline)
        }
    end

    # Interface::timelineWalk(timeline)
    def self.timelineWalk(timeline)
        tnodes = CoreData::getTimelineTNodesOrdered(timeline)
        counter = 0
        tnodes
            .each{|tnode|
                counter = counter + 1
                loop {
                    puts ""
                    puts "-> [#{counter}/#{tnodes.size}] #{tnode["description"]}"
                    operation = LucilleCore::askQuestionAnswerAsString("operation (open, dive, destroy, exit walk) [nothing for next]: ")
                    if operation == "open" then
                        Interface::optimizedOpenTNodeUniqueTargetOrNothing(tnode)
                    end
                    if operation == "dive" then
                        Interface::tNodeDive(tnode["uuid"])
                    end
                    if operation == "destroy" then
                        if LucilleCore::askQuestionAnswerAsBoolean("Do you want to destroy this item? ") then
                            Estate::destroyTNode(tnode)
                            break
                        end
                    end
                    if operation == "exit walk" then
                        return
                    end
                }
            }
    end

    # Interface::ui()
    def self.ui()
        loop {
            operations = [
                "make new item",
                "search",
                "view most recent items",
                "timelines dive",
                "timeline walk"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "make new item" then
                TMakers::makeNewTNode()
            end
            if operation == "search" then
                pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
                tnodes = CoreData::searchPatternToTNodes(pattern)
                Interface::tNodesDive(tnodes)
            end
            if operation == "view most recent items" then
                tnodes = Estate::tnodeEnumerator().to_a.reverse.take(10)
                Interface::tNodesDive(tnodes)
            end
            if operation == "timelines dive" then
                Interface::timelinesDive()
            end
            if operation == "timeline walk" then
                timeline = TMakers::interactivelySelectTimelineOrNull()
                next if timeline.nil?
                Interface::timelineWalk(timeline)
            end
        }
    end

end

