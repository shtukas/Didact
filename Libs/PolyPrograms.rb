
class PolyPrograms

    # PolyPrograms::catalystMainListing()
    def self.catalystMainListing()
        system("clear")

        vspaceleft = CommonUtils::screenHeight()-3

        if Config::get("instanceId") == "Lucille20-pascal" then
            reference = The99Percent::getReferenceOrNull()
            current   = The99Percent::getCurrentCount()
            ratio     = current.to_f/reference["count"]
            line      = "👩‍💻 🔥 #{current} #{ratio} ( #{reference["count"]} @ #{reference["datetime"]} )"
            puts ""
            puts line
            vspaceleft = vspaceleft - 2
            if ratio < 0.99 then
                The99Percent::issueNewReferenceOrNull()
            end
        end

        store = ItemStore.new()

        if !InternetStatus::internetIsActive() then
            puts "INTERNET IS OFF".green
            vspaceleft = vspaceleft - 2
        end

        puts ""
        vspaceleft = vspaceleft - 1

        tops = TopLevel::items()
        tops.each{|item|
            store.register(item, false)
            line = "#{store.prefixString()} #{PolyFunctions::toString(item)}".yellow
            if NxBallsService::isPresent(item["uuid"]) then
                line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
        }
        puts ""
        vspaceleft = vspaceleft - 1

        floats = TxFloats::listingItems()
        floats.each{|item|
            store.register(item, false)
            line = "#{store.prefixString()} #{PolyFunctions::toString(item)}".yellow
            if NxBallsService::isPresent(item["uuid"]) then
                line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
        }
        puts ""
        vspaceleft = vspaceleft - 1

        listingItems = CatalystListing::listingItems()

        displayedOneNxBall = false
        NxBallsIO::nxballs()
            .sort{|t1, t2| t1["unixtime"] <=> t2["unixtime"] }
            .each{|nxball|
                displayedOneNxBall = true
                store.register(nxball, false)
                line = "#{store.prefixString()} [running] #{nxball["description"]} (#{NxBallsService::activityStringOrEmptyString("", nxball["uuid"], "")})"
                puts line.green
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }
        if displayedOneNxBall then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        inbox = InboxItems::listingItems()
        inbox.each{|item|
            store.register(item, false)
            line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
            if NxBallsService::isPresent(item["uuid"]) then
                line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
            end
            puts line
            vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
        }
        if !inbox.empty? then
            puts ""
            vspaceleft = vspaceleft - 1
        end

        CatalystListing::listingItems()
            .each{|item|
                break if vspaceleft <= 0
                store.register(item, true)
                line = "#{store.prefixString()} #{PolyFunctions::toString(item)}"
                if NxBallsService::isPresent(item["uuid"]) then
                    line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", item["uuid"], "")})".green
                end
                puts line
                vspaceleft = vspaceleft - CommonUtils::verticalSize(line)
            }

        CommandInterpreter::commandPrompt(store)
    end

    # PolyPrograms::landing(item)
    def self.landing(item)

        PolyFunctions::_check(item, "PolyPrograms::landing")

        if item["mikuType"] == "fitness1" then
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return nil
        end

        loop {
            return nil if item.nil?
            uuid = item["uuid"]
            item = DxF1::getProtoItemOrNull(uuid)
            return nil if item.nil?
            system("clear")
            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            store = ItemStore.new()
            # We register the item which is also the default element in the store
            store.register(item, true)
            entities = NetworkLinks::linkedEntities(item["uuid"])
            if entities.size > 0 then
                puts ""
                if entities.size < 200 then
                    entities
                        .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                        .each{|entity|
                            store.register(entity, false)
                            puts "#{store.prefixString()} #{PolyFunctions::toString(entity)}"
                        }
                else
                    puts "(... many entities, use `navigation` ...)"
                end
            end

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyPrograms::landing(entity)
                next
            end

            CommandInterpreter::run(input, store)
        }
    end

    # PolyPrograms::timeCommitmentProgram(item)
    def self.timeCommitmentProgram(item)
        loop {
            system("clear")

            puts TxTimeCommitmentProjects::toString(item).green

            store = ItemStore.new()

            items = TxTimeCommitmentProjects::elements(item, 6)
            if items.size > 0 then
                puts ""
                puts "Managed Items:"
                items
                    .map{|element|
                        {
                            "element" => element,
                            "rt"      => BankExtended::stdRecoveredDailyTimeInHours(element["uuid"])
                        }
                    }
                    .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
                    .map{|px| px["element"] }
                    .each{|element|
                        indx = store.register(element, false)
                        line = "#{store.prefixString()} #{PolyFunctions::toString(element)}"
                        if NxBallsService::isPresent(element["uuid"]) then
                            line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", element["uuid"], "")})".green
                        end
                        puts line
                    }
            end

            items = TxTimeCommitmentProjects::elements(item, 50)
            if items.size > 0 then
                puts ""
                puts "Tail (items.size items):"
                TxTimeCommitmentProjects::elements(item, 50)
                    .each{|element|
                        indx = store.register(element, false)
                        line = "#{store.prefixString()} #{PolyFunctions::toString(element)}"
                        if NxBallsService::isPresent(element["uuid"]) then
                            line = "#{line} (#{NxBallsService::activityStringOrEmptyString("", element["uuid"], "")})".green
                        end
                        puts line
                    }
            end

            puts ""
            puts "commands: ax39 | insert | detach <n> | transfer <n> | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if command == "ax39"  then
                ax39 = Ax39::interactivelyCreateNewAx()
                DxF1::setAttribute2(item["uuid"], "ax39",  ax39)
                return
            end

            if command == "insert" then
                type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "task"])
                next if type.nil?
                if type == "line" then
                    element = NxLines::interactivelyIssueNewLineOrNull()
                    next if element.nil?
                    OwnerMapping::issue(item["uuid"], element["uuid"])
                end
                if type == "task" then
                    element = NxTasks::interactivelyCreateNewOrNull(false)
                    next if element.nil?
                    OwnerMapping::issue(item["uuid"], element["uuid"])
                end
                next
            end

            if  command.start_with?("detach") and command != "detach" then
                indx = command[6, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                OwnerMapping::detach(item["uuid"], entity["uuid"])
                next
            end

            if  command.start_with?("transfer") and command != "transfer" then
                indx = command[8, 99].strip.to_i
                entity = store.get(indx)
                next if entity.nil?
                item2 = TxTimeCommitmentProjects::architectOneOrNull()
                return if item2.nil?
                OwnerMapping::issue(item2["uuid"], entity["uuid"])
                OwnerMapping::detach(item["uuid"], entity["uuid"])
                next
            end

            CommandInterpreter::run(command, store)
        }
        nil
    end
end
