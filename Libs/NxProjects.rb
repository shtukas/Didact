
class NxProjects

    # NxProjects::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxProject/#{uuid}.json"
    end

    # NxProjects::items()
    def self.items()
        items = LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxProject")
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .map{|filepath| JSON.parse(IO.read(filepath)) }
        XCache::set("NxProject-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E", items.map{|item| item["description"].size }.max)
        items
    end

    # NxProjects::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxProjects::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxProjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxProjects::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxProjects::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxProjects::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # Makers

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ax39"        => ax39,
            "isWork"      => false
        }
        FileSystemCheck::fsck_NxProject(item, true)
        NxProjects::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxProjects::itemsWithNonNullRatioOrdered()
    def self.itemsWithNonNullRatioOrdered()
        NxProjects::items()
            .select{|item| !Ax39::standardAx39CarrierOperationalRatioOrNull(item).nil? }
            .sort{|i1, i2| Ax39::standardAx39CarrierOperationalRatioOrNull(i1) <=> Ax39::standardAx39CarrierOperationalRatioOrNull(i2) }
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "(project) #{item["description"]}"
    end

    # NxProjects::toStringWithDetails(item)
    def self.toStringWithDetails(item)
        ratio = Ax39::standardAx39CarrierOperationalRatioOrNull(item)
        percentageStr = 
            if ratio then
                percentage = 100 * ratio
                percentageStr = ", #{percentage.round(2)} %"
            else
                ", ratio: null"
            end
        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ", (do not show until: #{datetimeOpt})" : ""

        "#{item["description"]}, #{Ax39::toString(item["ax39"])}#{percentageStr}#{dnsustr}"
    end

    # NxProjects::toStringWithDetailsFormatted(item)
    def self.toStringWithDetailsFormatted(item)
        descriptionPadding = (XCache::getOrNull("NxProject-Description-Padding-DDBBF46A-2D56-4931-BE11-AF66F97F738E") || 28).to_i # the original value
        
        ratio = Ax39::standardAx39CarrierOperationalRatioOrNull(item)
        percentageStr = 
            if ratio then
                percentage = 100 * ratio
                percentageStr = ", #{percentage.to_i.to_s.rjust(3)} %"
            else
                ", ratio: null"
            end

        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? ", (do not show until: #{datetimeOpt})" : ""

        "(project) #{item["description"].ljust(descriptionPadding)}, #{Ax39::toStringFormatted(item["ax39"]).ljust(18)}#{percentageStr}#{dnsustr}"
    end

    # NxProjects::itemToProject(item)
    def self.itemToProject(item)
        NxProjects::getOrNull(item["projectId"])
    end

    # NxProjects::projectsForListing()
    def self.projectsForListing()
        NxProjects::itemsWithNonNullRatioOrdered()
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| InternetStatus::itemShouldShow(item["uuid"]) }
            .select{|project| Ax39::standardAx39CarrierOperationalRatioOrNull(project) < 1 }
    end

    # NxProjects::firstNxTodoItemsForNxProject(projectId)
    def self.firstNxTodoItemsForNxProject(projectId)
        filepath = "#{Config::pathToDataCenter()}/NxProject-to-FirstItems/#{projectId}.json"

        getDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            packet["uuids"]
                .map{|uuid| NxTodos::getOrNull(projectId) }
                .compact
        }

        getRecentDataOrNull = lambda {|filepath|
            return nil if !File.exists?(filepath)
            packet = JSON.parse(IO.read(filepath))
            return nil if (Time.new.to_i - packet["unixtime"]) > 3600
            packet["uuids"]
                .map{|uuid| NxTodos::getOrNull(projectId) }
                .compact
        }

        issueNewFile = lambda {|filepath, projectId|
            items = NxTodos::itemsForNxProject(projectId)
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                        .first(10)
            uuids = items.map{|item| item["uuid"] }
            packet = {
                "unixtime" => Time.new.to_i,
                "uuids"    => uuids
            }
            File.open(filepath,  "w"){|f| f.puts(JSON.pretty_generate(packet)) }
            items
        }

        if Config::getOrNull("isLeaderInstance") then
            items = getRecentDataOrNull.call(filepath)
            return items if items
            return issueNewFile.call(filepath, projectId)
        else
            return (getDataOrNull.call(filepath) || [])
        end
    end

    # NxProjects::listingWorkItems()
    def self.listingWorkItems()
        mainFocusItem = lambda{|project|
            uuid = "Vx01-MainFocus-#{project["uuid"]}"
            ratio = Ax39::standardAx39CarrierOperationalRatioOrNull(project)
            return nil if ratio.nil?
            shouldShow = ratio < 0.75
            return nil if !shouldShow
            {
                "uuid"        => uuid,
                "mikuType"    => "Vx01",
                "unixtime"    => project["unixtime"],
                "description" => "Main Focus: '#{NxProjects::toString(project)}' (current ratio: #{ratio.round(2)}, until: 0.75)",
                "projectId"   => project["uuid"]
            }
        }
        NxProjects::projectsForListing()
            .select{|project| project["isWork"] }
            .map{|project| 
                focus = mainFocusItem.call(project)
                items = NxProjects::firstNxTodoItemsForNxProject(project["uuid"])
                (focus ? [focus] : []) + items + ((focus.nil? and items.empty?) ? [project] : [])
            }
            .flatten
    end

    # NxProjects::listingClassicProjects()
    def self.listingClassicProjects()
        NxProjects::projectsForListing()
            .select{|project| !project["isWork"] }
            .map{|project| 
                items = NxProjects::firstNxTodoItemsForNxProject(project["uuid"])
                items + (items.empty? ? [project] : [])
            }
            .flatten
    end

    # --------------------------------------------
    # Ops

    # NxProjects::interactivelySelectNxProjectOrNull()
    def self.interactivelySelectNxProjectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", NxProjects::items(), lambda{|project| NxProjects::toStringWithDetailsFormatted(project)})
    end

    # NxProjects::interactivelySelectProject()
    def self.interactivelySelectProject()
        loop {
            project = NxProjects::interactivelySelectNxProjectOrNull()
            return project if project
        }
    end

    # NxProjects::probe(project)
    def self.probe(project)
        loop {
            puts NxProjects::toStringWithDetails(project)
            puts "ratio: #{Ax39::standardAx39CarrierOperationalRatioOrNull(project)}"
            actions = ["start", "add time", "do not show until", "set Ax39", "expose", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "start" then
                PolyActions::start(project)
                return
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "adding #{timeInHours} hours to '#{NxProjects::toString(project)}'"
                Bank::put(project["uuid"], timeInHours*3600)
            end
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                next if unixtime.nil?
                DoNotShowUntil::setUnixtime(project["uuid"], unixtime)
            end
            if action == "set Ax39" then
                project["ax39"] = Ax39::interactivelyCreateNewAx()
                FileSystemCheck::fsck_NxProject(project, true)
                NxProjects::commit(project)
            end
            if action == "expose" then
                puts JSON.pretty_generate(project)
                LucilleCore::pressEnterToContinue()
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy NxProject '#{NxProjects::toString(project)}' ? ") then
                    filepath = "#{Config::pathToDataCenter()}/NxProject/#{project["uuid"]}.json"
                    FileUtils.rm(filepath)
                    return
                end
            end
        }
    end

    # NxProjects::mainprobe()
    def self.mainprobe()
        loop {
            system("clear")
            project = NxProjects::interactivelySelectNxProjectOrNull()
            return if project.nil?
            NxProjects::probe(project)
        }
    end
end
