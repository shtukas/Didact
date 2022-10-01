class PolyFunctions

    # ordering: alphabetical

    # PolyFunctions::edit(item) # item
    def self.edit(item)

        puts "PolyFunctions::edit(#{JSON.pretty_generate(item)})"

        # order: by mikuType

        if item["mikuType"] == "NyxNode" then
            return NyxNodes::edit(item)
        end

        if item["mikuType"] == "NxTodo" then
            return NxTodos::edit(item)
        end

        if item["mikuType"] == "Wave" then
            return Waves::edit(item)
        end

        if item["mikuType"] == "NxLine" then
            puts "NxLines are not editable (they _could_, they are just not)"
            return item
        end

        if item["mikuType"] == "NxTodo" then
            return NxTodos::edit(item)
        end

        puts "I do not know how to PolyFunctions::edit(#{JSON.pretty_generate(item)})"
        raise "(error: 628167a9-f6c9-4560-bdb0-4b0eb9579c86)"
    end

    # PolyFunctions::foxTerrierAtItem(item)
    def self.foxTerrierAtItem(item)
        loop {
            system("clear")
            puts "------------------------------".green
            puts "Fox Terrier Or Null (`select`)".green
            puts "------------------------------".green
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
                            indx = store.register(entity, false)
                            puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
                        }
                else
                    puts "(... many entities, use `navigation` ...)"
                end
            end

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return nil if input == ""

            if input == "select" then
                return item
            end

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                return if entity.nil?
                resultOpt = PolyFunctions::foxTerrierAtItem(entity)
                return resultOpt if resultOpt
            end
        }
    end

    # PolyFunctions::genericDescriptionOrNull(item)
    def self.genericDescriptionOrNull(item)

        # ordering: alphabetical order

        if item["mikuType"] == "InboxItem" then
            return item["description"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return item["description"]
        end
        if item["mikuType"] == "NxIced" then
            return item["description"]
        end
        if item["mikuType"] == "NxLine" then
            return item["line"]
        end
        if item["mikuType"] == "NxTodo" then
            return item["description"]
        end
        if item["mikuType"] == "NyxNode" then
            return item["description"]
        end
        if item["mikuType"] == "TxFloat" then
            return item["description"]
        end
        if item["mikuType"] == "TxThread" then
            return item["description"]
        end
        if item["mikuType"] == "Wave" then
            return item["description"]
        end
        return nil
    end

    # PolyFunctions::listingPriorityOrNull(item)
    # We return a null value when the item should not be displayed
    def self.listingPriorityOrNull(item) # Float between 0 and 1

        # NxAnniversary                 : 0.95
        # Nx11E hot                     : 0.90
        # Wave (priority)               : 0.90
        # Nx11E ordinal                 : 0.80
        # fitness1                      : 0.75
        # Nx11E ondate                  : 0.70
        # Nx11E Ax39Engine              : 0.50 (or 0.2 if above completion)
        # Wave (low priority)           : 0.40
        # Nx11E standard                : 0.20 

        # NxTodo 0.4 or Nx11E derived value

        # Wave

        shiftOnDateTime = lambda {|item, datetime|
            0.01*(Time.new.to_f - DateTime.parse(datetime).to_time.to_f)/86400
        }

        shiftOnUnixtime = lambda {|item, unixtime|
            0.01*Math.log(Time.new.to_f - unixtime)
        }

        # ordering: alphabetical order

        if item["mikuType"] == "fitness1" then
            return 0.75
        end

        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::isOpenToAcknowledgement(anniversary) ? 0.95 : -1
        end

        if item["mikuType"] == "NxTodo" then
            return NxTodos::listingPriorityOrNull(item)
        end

        if item["mikuType"] == "Wave" then
            return (Waves::isPriority(item) ? 0.9 : 0.4) + shiftOnDateTime.call(item, item["lastDoneDateTime"])
        end

        raise "(error: 4302a0f5-91a0-4902-8b91-e409f123d305) no priority defined for item: #{item}"
    end

    # PolyFunctions::timeBeforeNotificationsInHours(item)
    def self.timeBeforeNotificationsInHours(item)
        1
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        if item["mikuType"] == "fitness1" then
            return item["announce"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBall.v2" then
            return item["description"]
        end
        if item["mikuType"] == "NxLine" then
            return "(line) #{item["line"]}"
        end
        if item["mikuType"] == "NxTodo" then
            return NxTodos::toString(item)
        end
        if item["mikuType"] == "NyxNode" then
            return NyxNodes::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end
end
