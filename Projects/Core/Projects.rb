
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

require 'colorize'

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::ping(uuid, weight, validityTimespan)
    Ping::pong(uuid)
=end

# -----------------------------------------------------------------

class Projects

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

    # Projects::getStandardProjects()
    def self.getStandardProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "standard" }
            .sort{|p1, p2| p1["creationtime"] <=> p2["creationtime"] }
    end

    # Projects::getAckProjects()
    def self.getAckProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "ack" }
            .sort{|p1, p2| p1["creationtime"] <=> p2["creationtime"] }
    end

    # Projects::getProjectByUUIDOrNUll(uuid)
    def self.getProjectByUUIDOrNUll(uuid)
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Projects::saveProject(project)
    def self.saveProject(project)
        File.open("#{Projects::pathToProjects()}/#{project["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(project)) }
    end

    # Projects::destroyProject(project)
    def self.destroyProject(project)
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
            "schedule"     => schedule,
            "items"        => items
        }
    end

    # Projects::issueProject(uuid, description, schedule, items)
    def self.issueProject(uuid, description, schedule, items)
        project = Projects::makeProject(uuid, description, schedule, items)
        Projects::saveProject(project)
        project
    end

    # Projects::projectToString(project)
    def self.projectToString(project)

        projectKickerText = lambda {|project|
            uuid = project["uuid"]
            "[project #{project["schedule"]["type"].rjust(8)}] (#{"%7.2f" % (Ping::pong(uuid).to_f/3600)} hours)"
        }

        projectSuffixText = lambda {|project|
            uuid = project["uuid"]
            str1 = " (#{Items::getItemsByCreationTime(project["uuid"]).size})"
            str2 = 
                if Runner::isRunning(uuid) then
                    " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
                else
                    ""
                end
            "#{str1}#{str2}"
        }

        "#{projectKickerText.call(project)} #{project["description"]}#{projectSuffixText.call(project)}"
    end

    # Projects::projectMetric(project)
    def self.projectMetric(project)
        projectuuid = project["uuid"]

        claims = IfcsClaims::getClaimsOfTypeProjectByUuid(projectuuid)
        if claims.size > 0 then
            return claims.map{|ifcsclaim| IfcsClaims::claimMetric(ifcsclaim) }.max
        end

        return 0 if project["schedule"]["type"] == "ack"
        return 0.68 if projectuuid == "44caf74675ceb79ba5cc13bafa102509369c2b53" # Inbox
        0.2 + 0.46*Math.exp(-(Ping::pong(projectuuid).to_f/86400))
    end

    # Projects::selectProjectInteractivelyOrNull()
    def self.selectProjectInteractivelyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", Projects::projects().sort{|p1, p2| p1["description"] <=> p2["description"] }, lambda {|project| Projects::projectToString(project) })
    end

    # Projects::selectProjectFromExistingOrNewOrNull()
    def self.selectProjectFromExistingOrNewOrNull()

        project = Projects::selectProjectInteractivelyOrNull()
        return project if project

        puts "-> No project select. Please give a description to make a new one (empty for aborting operation)"
        description = LucilleCore::askQuestionAnswerAsString("description: ")

        if description == "" then
            return nil
        end

        puts "-> Choosing project schedule type"
        scheduletype = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("project schedule type", ["standard", "ack"])

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
        puts JSON.pretty_generate(schedule)

        Projects::issueProject(SecureRandom.uuid, description, schedule, []) # Project
    end

    # Projects::makeNewScheduleInteractiveOrNull()
    def self.makeNewScheduleInteractiveOrNull()
        puts "-> Choosing project schedule type"
        scheduletype = LucilleCore::selectEntityFromListOfEntitiesOrNull("project schedule type", ["standard", "ack"])
        return nil if scheduletype.nil?
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
        puts JSON.pretty_generate(schedule)
        schedule
    end

    # Projects::openProject(project)
    def self.openProject(project)
        items = Items::getItemsByCreationTime(project["uuid"])
        if items.size == 1 then
            Items::openItem(items[0])
            return
        end
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Items::itemBestDescription(item) })
        return if item.nil?
        Items::openItem(item)
    end

    # Projects::diveProject(project)
    def self.diveProject(project)
        loop {
            system("clear")
            puts Projects::projectToString(project).green
            puts JSON.pretty_generate(project)
            puts JSON.pretty_generate(IfcsClaims::getClaimsOfTypeProjectByUuid(project["uuid"]))
            puts "metric: #{Projects::projectMetric(project)}".green
            options = [
                "dive items",
                "make and attach new item",
                "set project description",
                "recast project schedule",
                "dive ifcs claims"
            ]
            if IfcsClaims::getClaimsOfTypeProjectByUuid(project["uuid"]).empty? then
                options.delete("dive ifcs claims")
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "dive items" then
                items = Items::getItemsByCreationTime(project["uuid"])
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Items::itemBestDescription(item) })
                next if item.nil?
                Items::diveItem(project, item)
            end
            if option == "make and attach new item" then
                catalystStandardTarget = CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
                next if catalystStandardTarget.nil?
                item = {
                    "uuid"         => SecureRandom.uuid,
                    "creationtime" => Time.new.to_f,
                    "description"  => LucilleCore::askQuestionAnswerAsString("item description: "),
                    "target"       => catalystStandardTarget
                }
                Items::attachItemToProject(project["uuid"], item)
            end
            if option == "set project description" then
                project["description"] = CatalystCommon::editTextUsingTextmate(project["description"])
                Projects::saveProject(project)
            end
            if option == "recast project schedule" then
                schedule = Projects::makeNewScheduleInteractiveOrNull()
                next if schedule.nil?
                project["schedule"] = schedule
                Projects::saveProject(project)
            end
            if option == "dive ifcs claims" then
                claims = IfcsClaims::getClaimsOfTypeProjectByUuid(project["uuid"])
                loop {
                    ifcsclaim = LucilleCore::selectEntityFromListOfEntitiesOrNull("claim", claims, lambda{|claim| IfcsClaims::ifcsClaimToString(claim) })
                    break if ifcsclaim.nil?
                    IfcsClaims::diveIfcsClaim(ifcsclaim)
                }
            end
        }
    end

    # Projects::receiveRunTimespan(projectuuid, timespan)
    def self.receiveRunTimespan(projectuuid, timespan)
        Ping::ping(projectuuid, timespan, Utils::pingRetainPeriodInSeconds())
        IfcsClaims::getClaimsOfTypeProjectByUuid(projectuuid).each{|claim|
            Ping::ping(claim["uuid"], timespan, Utils::pingRetainPeriodInSeconds())
        }
    end

end
