
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"
=begin

    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::exists?(filename)
    CoreDataFile::openOrCopyToDesktop(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::openFolder(foldername)

=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTarget.rb"
=begin 
    CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    CatalystStandardTarget::targetToString(target)
    CatalystStandardTarget::openTarget(target)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Runner.rb"
=begin 
    Runner::isRunning(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

# -----------------------------------------------------------------

class Projects

    # -----------------------------------------------------------
    # Projects

    # Projects::pathToProjects()
    def self.pathToProjects()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Projects/projects1"
    end

    # Projects::projects()
    def self.projects()
        Dir.entries(Projects::pathToProjects())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Projects::pathToProjects()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # Projects::getIFCSProjects()
    def self.getIFCSProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "ifcs" }
            .sort{|p1, p2| p1["schedule"]["position"] <=> p2["schedule"]["position"] }
    end

    # Projects::getStandardProjects()
    def self.getStandardProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "standard" }
            .sort{|p1, p2| p1["creationtime"] <=> p2["creationtime"] }
    end

    # Projects::getProjectByUUIDOrNUll(uuid)
    def self.getProjectByUUIDOrNUll(uuid)
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Projects::save(project)
    def self.save(project)
        File.open("#{Projects::pathToProjects()}/#{project["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(project)) }
    end

    # Projects::destroy(project)
    def self.destroy(project)
        uuid = project["uuid"]
        return if uuid == "20200502-141331-226084" # Guardian General Work
        return if uuid == "44caf74675ceb79ba5cc13bafa102509369c2b53" # Inbox
        return if uuid == "0219fd54bd5841008b18c414a5b2dea331bad1c5" # Infinity
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Projects::makeProject(uuid, description, schedule, items)
    def self.makeProject(uuid, description, schedule, items)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "schedule" => schedule,
            "items"        => items
        }
    end

    # Projects::issueProject(uuid, description, schedule, items)
    def self.issueProject(uuid, description, schedule, items)
        project = Projects::makeProject(uuid, description, schedule, items)
        Projects::save(project)
        project
    end

    # Projects::selectProjectOrNull()
    def self.selectProjectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project:", Projects::projects(), lambda {|project| project["description"] })
    end

    # Projects::selectProjectFromExistingOrNewOrNull()
    def self.selectProjectFromExistingOrNewOrNull()

        project = Projects::selectProjectOrNull()
        return project if project

        puts "-> No project select. Please give a description to make a new one (empty for aborting operation)"
        description = LucilleCore::askQuestionAnswerAsString("description: ")

        if description == "" then
            return nil
        end

        puts "-> Choosing project schedule type"
        scheduletype = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("project schedule type", ["standard", "ack", "ifcs"])

        puts "-> Making schedule"
        schedule = nil
        if scheduletype == "standard" then
            schedule = {
                "type"  => "standard"
            }
        end
        if scheduletype == "ack" then
            schedule = {
                "type" => "ack"
            }
        end
        if scheduletype == "ifcs" then
            schedule = {
                "type" => "ifcs",
                "position" => CatalystCommon::interactivelyGetIfcsPosition()
            }
        end
        puts JSON.pretty_generate(schedule)

        Projects::issueProject(SecureRandom.uuid, description, schedule, []) # Project
    end

    # -----------------------------------------------------------
    # Items Management

    # Projects::attachProjectItemToProject(projectuuid, item)
    def self.attachProjectItemToProject(projectuuid, item)
        # There is a copy of function in LucilleTxt/catalyst-objects-processing
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, item["uuid"], item)
    end

    # Projects::getProjectItemOrNull(projectuuid, itemuuid)
    def self.getProjectItemOrNull(projectuuid, itemuuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Projects::getProjectItemsByCreationTime(projectuuid)
    def self.getProjectItemsByCreationTime(projectuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid)
            .sort{|i1, i2| i1["creationtime"]<=>i2["creationtime"] }
    end

    # Projects::detachProjectItemFromProject(projectuuid, itemuuid)
    def self.detachProjectItemFromProject(projectuuid, itemuuid)
        BTreeSets::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Projects::projectItemToString(item)
    def self.projectItemToString(item)
        item["description"] || CatalystStandardTarget::targetToString(item["target"])
    end

    # Projects::projectItemToCatalystObject(project, item, basemetric, indx)
    def self.projectItemToCatalystObject(project, item, basemetric, indx)
        uuid = item["uuid"]
        {
            "uuid"           => uuid,
            "contentItem"    => {
                "type" => "line",
                "line" => "[project item] #{Projects::projectItemToString(item)}"
            },
            "metric"         => basemetric - indx.to_f/10000,
            "commands"       => ["open", "done", "recast"],
            "defaultCommand" => "open",
            "shell-redirects" => {
                "open"   => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Projects/catalyst-objects-processing project-item-open '#{project["uuid"]}' '#{uuid}'",
                "done"   => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Projects/catalyst-objects-processing project-item-done '#{project["uuid"]}' '#{uuid}'",
                "recast" => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Projects/catalyst-objects-processing project-item-recast '#{project["uuid"]}' '#{uuid}'"
            }
        }
    end

    # Projects::recastItem(projectuuid, itemuuid)
    def self.recastItem(projectuuid, itemuuid)
        item = Projects::getProjectItemOrNull(projectuuid, itemuuid)
        return if item.nil?
        # We need to choose a project, possibly a new one and add the item to it and remove the item from the original project
        targetproject = Projects::selectProjectFromExistingOrNewOrNull()
        Projects::attachProjectItemToProject(targetproject["uuid"], item)
        Projects::detachProjectItemFromProject(projectuuid, itemuuid)
    end

    # -----------------------------------------------------------
    # Run Management

    # Projects::insertAlgebraicTime(uuid, algebraicTimespanInSeconds)
    def self.insertAlgebraicTime(uuid, algebraicTimespanInSeconds)
        timepoint = {
            "uuid"     => SecureRandom.uuid,
            "unixtime" => Time.new.to_i,
            "timespan" => algebraicTimespanInSeconds
        }
        BTreeSets::set(nil, "acc68599-2249-42fc-b6dd-f7db287c73db:#{uuid}", timepoint["uuid"], timepoint)
    end

    # Projects::getTimepoints(uuid)
    def self.getTimepoints(uuid)
        BTreeSets::values(nil, "acc68599-2249-42fc-b6dd-f7db287c73db:#{uuid}")
    end

    # Projects::getStoredRunTimespan(uuid)
    def self.getStoredRunTimespan(uuid)
        Projects::getTimepoints(uuid)
            .map{|point| point["timespan"] }
            .inject(0, :+)
    end

    # Projects::getStoredRunTimespanOverThePastNSeconds(uuid, n)
    def self.getStoredRunTimespanOverThePastNSeconds(uuid, n)
        Projects::getTimepoints(uuid)
            .select{|timepoint| (Time.new.to_f - timepoint["unixtime"]) <= n }
            .map{|point| point["timespan"] }
            .inject(0, :+)
    end

    # -----------------------------------------------------------
    # In Flight Control System

    # Projects::getOrderedIfcsProjectsWithComputedOrdinal()
    def self.getOrderedIfcsProjectsWithComputedOrdinal() # Array[ (project, ordinal: Int) ]
        Projects::getIFCSProjects()
            .map
            .with_index
            .to_a
    end

    # Projects::getOrdinal(uuid)
    def self.getOrdinal(uuid)
        Projects::getOrderedIfcsProjectsWithComputedOrdinal()
            .select{|pair| pair[0]["uuid"] == uuid }
            .map{|pair| pair[1] }
            .first
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # Projects::interactiveChoiceOfPosition()
    def self.interactiveChoiceOfPosition() # Float
        puts "Items"
        Projects::getIFCSProjects()
            .each{|project|
                uuid = project["uuid"]
                puts "    - #{("%5.3f" % project["schedule"]["position"])} #{project["description"]}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # Projects::uuidTotalTimespanIncludingLiveRun(uuid)
    def self.uuidTotalTimespanIncludingLiveRun(uuid)
        x0 = Projects::getStoredRunTimespan(uuid)
        x1 = 0
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        if unixtime then
            x1 = Time.new.to_f - unixtime.to_f
        end
        x0 + x1
    end

    # Projects::projectIsInboxAndHasItems(projectuuid)
    def self.projectIsInboxAndHasItems(projectuuid)
        b1 = projectuuid == "44caf74675ceb79ba5cc13bafa102509369c2b53"
        b2 = !Projects::getProjectItemsByCreationTime(projectuuid).empty?
        b1 and b2
    end

    # Projects::timeToMetric(uuid, timeInSeconds)
    def self.timeToMetric(uuid, timeInSeconds)
        return 1 if Runner::isRunning(uuid)
        return 0.77 if Projects::projectIsInboxAndHasItems(uuid)
        return 0 if timeInSeconds > 0 # We kill any item that is not late
        timeInHours = timeInSeconds.to_f/3600
        0.76 + Math.atan(-timeInHours).to_f/1000
    end

    # Projects::ifcsMetric(uuid)
    def self.ifcsMetric(uuid)
        Projects::timeToMetric(uuid, Projects::getStoredRunTimespan(uuid))
    end

    # Projects::isWeekDay()
    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    # Projects::operatingTimespanMapping()
    def self.operatingTimespanMapping()
        if Projects::isWeekDay() then
            {
                "GuardianGeneralWork" => 5 * 3600,
                "IFCSStandard"        => 2 * 3600
            }
        else
            {
                "GuardianGeneralWork" => 0 * 3600,
                "IFCSStandard"        => 4 * 3600
            }
        end
    end

    # Projects::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    def self.ordinalTo24HoursTimeExpectationInSeconds(ordinal)
        Projects::operatingTimespanMapping()["IFCSStandard"] * (1.to_f / 2**(ordinal+1))
    end

    # Projects::itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
    def self.itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
        return nil if Projects::getStoredRunTimespan(uuid) < -3600 # This allows small targets to get some time and the big ones not to become overwelming
        if uuid == "20200502-141331-226084" then # Guardian General Work
            return Projects::operatingTimespanMapping()["GuardianGeneralWork"]
        end
        Projects::ordinalTo24HoursTimeExpectationInSeconds(Projects::getOrdinal(uuid))
    end

    # Projects::distributeDayTimeCommitmentsIfNotDoneAlready()
    def self.distributeDayTimeCommitmentsIfNotDoneAlready()
        return if Time.new.hour < 9
        return if Time.new.hour > 18
        Projects::getIFCSProjects()
            .each{|project|
                uuid = project["uuid"]
                next if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
                timespan = Projects::itemPractical24HoursTimeExpectationInSecondsOrNull(uuid)
                next if timespan.nil?
                Projects::insertAlgebraicTime(uuid, -timespan)
                KeyValueStore::setFlagTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
            }
    end

    # -----------------------------------------------------------
    # Fsck

    # Projects::fsckItem(item)
    def self.fsckItem(item)
        puts JSON.pretty_generate(item)
        if item["uuid"].nil? then
            puts item
            raise "Project item has no uuid"
        end
        if item["creationtime"].nil? then
            puts item
            raise "Project item has no creationtime"
        end
        if item["target"].nil? then
            puts item
            raise "Project item has no target"
        end
        target = item["target"]
        CatalystStandardTarget::fsckTarget(target)
    end

    # Projects::fsckProject(project)
    def self.fsckProject(project)
        puts JSON.pretty_generate(project)
        if project["uuid"].nil? then
            puts project
            raise "Project has no uuid"
        end
        if project["creationtime"].nil? then
            puts project
            raise "Project has no creationtime"
        end
        if project["description"].nil? then
            puts project
            raise "Project has no description"
        end
        if project["schedule"].nil? then
            puts project
            raise "Project has no schedule"
        end
        items = Projects::getProjectItemsByCreationTime(project["uuid"])
        items.each{|item|
            Projects::fsckItem(item)
        }
    end

    # -----------------------------------------------------------
    # User Interface

    # Projects::projectKickerText(project)
    def self.projectKickerText(project)
        uuid = project["uuid"]
        if project["schedule"]["type"] == "standard" then
            return "[project standard ; time: #{"%7.2f" % (Projects::getStoredRunTimespan(uuid).to_f/3600)} hours]"
        end
        if project["schedule"]["type"] == "ifcs" then
            return "[project ifcs ; pos: #{("%6.3f" % project["schedule"]["position"])} ; ord: #{"%2d" % Projects::getOrdinal(uuid)} ; time: #{"%5.2f" % (Projects::getStoredRunTimespan(uuid).to_f/3600)}]"
        end
        raise "Projects: f40a0f00"
    end

    # Projects::projectSuffixText(project)
    def self.projectSuffixText(project)
        uuid = project["uuid"]
        str1 = " (#{Projects::getProjectItemsByCreationTime(project["uuid"]).size})"
        str2 = 
            if Runner::isRunning(uuid) then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        if project["schedule"]["type"] == "standard" then
            return "#{str1}#{str2}"
        end
        if project["schedule"]["type"] == "ifcs" then
            return "#{str1}#{str2}"
        end
        raise "Projects: 85cdae2a"
    end

    # Projects::projectToString(project)
    def self.projectToString(project)
        "#{Projects::projectKickerText(project)} #{project["description"]}#{Projects::projectSuffixText(project)}"
    end

    # Projects::diveProject(project)
    def self.diveProject(project)
        loop {
            system("clear")
            puts "project: #{Projects::projectToString(project)}"
            puts "uuid: #{project["uuid"]}"
            puts "description: #{project["description"]}"
            puts "schedule: #{project["schedule"]}"
            options = [
                "start",
                "dive items"
            ]
            if project["schedule"]["type"] == "ifcs" then
                options << "set ifcs position"
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "start" then
                Runner::start(project["uuid"])
            end
            if option == "dive items" then
                items = Projects::getProjectItemsByCreationTime(project["uuid"])
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Projects::projectItemToString(item) })
                next if item.nil?
                Projects::diveItem(project, item)
            end
            if option == "set ifcs position" then
                puts "--------------------"
                Projects::getIFCSProjects()
                    .each{|project|
                        puts Projects::projectToString(project)
                    }
                puts "--------------------"
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                project["schedule"]["position"] = position
                Projects::save(project)
            end
        }
    end

    # Projects::diveItem(project, item)
    def self.diveItem(project, item)
        loop {
            system("clear")
            puts "project item: #{Projects::projectItemToString(item)}"
            puts "uuid: #{item["uuid"]}"
            puts "description: #{item["description"]}"
            puts "target: #{item["target"]}"
            options = [
                "open",
                "done",
                "set description"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "open" then
                CatalystStandardTarget::openTarget(item["target"])
            end
            if option == "done" then
                Projects::detachProjectItemFromProject(project["uuid"], item["uuid"])
            end
            if option == "set description" then
                item["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
                Projects::attachProjectItemToProject(project["uuid"], item)
            end
        }
    end
end



