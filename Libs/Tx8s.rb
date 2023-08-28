
class Tx8s

    # ------------------------------------
    # IO

    # Tx8s::make(uuid, position)
    def self.make(uuid, position)
        {
            "uuid"     => uuid,
            "position" => position
        }
    end

    # ------------------------------------
    # Data

    # Tx8s::childrenInOrder(parent)
    def self.childrenInOrder(parent)
        Catalyst::catalystItems()
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == parent["uuid"] }
            .sort_by{|item| item["parent"]["position"] }
    end

    # Tx8s::repositionItemAtSameParent(item)
    def self.repositionItemAtSameParent(item)
        return if item["parent"].nil?
        parent = Cubes::itemOrNull(item["parent"]["uuid"])
        return if parent.nil?
        tx8 = item["parent"]
        position = Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
        return if position.nil?
        tx8["position"] = position
        Cubes::setAttribute2(item["uuid"], "parent", tx8)
    end

    # Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
    def self.interactivelyDecidePositionUnderThisParentOrNull(parent)

        if parent["uuid"] == "77a43c09-4642-45ff-b174-09898175919a" then # CoP
            return rand
        end

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["new first position", "careful positioning", "next (default)"])
        if option == "new first position" then
            return Tx8s::newFirstPositionAtThisParent(parent)
        end
        if option == "careful positioning" then
            children = Tx8s::childrenInOrder(parent).take(20)
            return 1 if children.empty?
            puts "positioning:"
            children.each{|item|
                puts " - #{PolyFunctions::toString(item)}"
            }
            position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
            if position == "" then
                return Tx8s::nextPositionAtThisParent(parent)
            else
                return position.to_f
            end
        end
        if option == "next (default)" or option.nil? then
            return Tx8s::nextPositionAtThisParent(parent)
        end
    end

    # Tx8s::reorganise(item)
    def self.reorganise(item)
        children = Tx8s::childrenInOrder(item)
                    .select{|i| i["mikuType"] == "NxTask" }
        if children.size < 2 then
            puts "item has #{children.size} children, nothing to organise"
            LucilleCore::pressEnterToContinue()
            return
        end

        sorted = []
        unsorted = children
        garbageCollected = []

        while unsorted.size > 0 do
            system('clear')
            puts ""
            puts "sorted:"
            sorted.each{|i|
                puts "    - #{PolyFunctions::toString(i)}"
            }
            puts ""
            puts "garbage collected:"
            garbageCollected.each{|i|
                puts "    - #{PolyFunctions::toString(i)}"
            }
            puts ""
            puts "unsorted:"
            i = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", unsorted, lambda{|i| PolyFunctions::toString(i) })
            next if i.nil?
            command = LucilleCore::askQuestionAnswerAsString("> command (keep, destroy, run+destroy): ")
            if command == "keep" then
                sorted << i
                unsorted = unsorted.reject{|x| x["uuid"] == i["uuid"]}
            end
            if command == "destroy" then
                garbageCollected << i
                unsorted = unsorted.reject{|x| x["uuid"] == i["uuid"]}
            end
            if command == "run+destroy" then
                puts "starting and running"
                NxBalls::start(item)
                PolyActions::access(item)
                LucilleCore::pressEnterToContinue("Press enter to garbage collect")
                garbageCollected << i
                unsorted = unsorted.reject{|x| x["uuid"] == i["uuid"]}
            end
        end

        puts ""
        puts "final:"
        sorted.each{|i|
            puts "    - #{PolyFunctions::toString(i)}"
        }

        puts ""
        puts "going to be destroyed:"
        garbageCollected.each{|i|
            puts "    - #{PolyFunctions::toString(i)}"
        }

        puts ""
        LucilleCore::pressEnterToContinue()
        sorted.each_with_index{|i, indx|
            i["parent"]["position"] = indx+1
            puts JSON.pretty_generate(i)
            Cubes::setAttribute2(i["uuid"], "parent", i["parent"])
        }

        garbageCollected.each{|i|
            Cubes::destroy(i["uuid"])
        }
    end

    # Tx8s::newFirstPositionAtThisParent(parent)
    def self.newFirstPositionAtThisParent(parent)
        ([0] + Tx8s::childrenInOrder(parent).map{|item| item["parent"]["position"] }).min - 1
    end

    # Tx8s::nextPositionAtThisParent(parent)
    def self.nextPositionAtThisParent(parent)
        ([0] + Tx8s::childrenInOrder(parent).map{|item| item["parent"]["position"] }).max + 1
    end

    # Tx8s::decide1020position(parent)
    def self.decide1020position(parent)
        positions = Tx8s::childrenInOrder(parent).map{|item| item["parent"]["position"] }
        return 1 if positions.empty?
        if positions.size < 20 then
            return positions.max + 1
        end
        positions = positions.drop(10).take(10)
        positions.min + rand * ( positions.max - positions.min )
    end

    # Tx8s::interactivelyMakeTx8AtParentOrNull(parent)
    def self.interactivelyMakeTx8AtParentOrNull(parent)
        puts "parent: #{PolyFunctions::toString(parent)}"
        position = Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
        return nil if position.nil?
        Tx8s::make(parent["uuid"], position)
    end

    # Tx8s::interactivelyPlaceItemAtParentAttempt(item, parent)
    def self.interactivelyPlaceItemAtParentAttempt(item, parent)
        tx8 = Tx8s::interactivelyMakeTx8AtParentOrNull(parent)
        return if tx8.nil?
        Cubes::setAttribute2(item["uuid"], "parent", tx8)
    end

    # Tx8s::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parent"].nil?
        Cubes::itemOrNull(item["parent"]["uuid"])
    end

    # Tx8s::positionInParentSuffix(item)
    def self.positionInParentSuffix(item)
        return "" if item["parent"].nil?
        " (#{"%5.2f" % item["parent"]["position"]})"
    end

    # Tx8s::pileAtThisParent(parent)
    def self.pileAtThisParent(parent)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text.lines.to_a.map{|line| line.strip }.select{|line| line.size > 0 }.reverse.each {|line|
            t1 = NxTasks::descriptionToTask(line)
            next if t1.nil?
            t1["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            puts JSON.pretty_generate(t1)
            Cubes::setAttribute2(t1["uuid"], "parent", t1["parent"])
        }
    end

    # Tx8s::suffix(item)
    def self.suffix(item)
        return "" if item["parent"].nil?
        parent = Cubes::itemOrNull(item["parent"]["uuid"])
        return "" if parent.nil?
        " (#{parent["description"]})"
    end

    # Tx8s::interactivelySelectParentOrNull(cursor = nil)
    def self.interactivelySelectParentOrNull(cursor = nil)
        if cursor.nil? then
            core = TxCores::interactivelySelectOneOrNull()
            return Tx8s::interactivelySelectParentOrNull(core)
        end
        child = Catalyst::selectChildUnderneathParentOrNull(cursor)
        return child if child["mikuType"] == "NxThread"
        cursor
    end

    # Tx8s::moveItem(item, envelop = nil)
    def self.moveItem(item, envelop = nil)
        Tx8s::moveItems([item], envelop)
    end

    # Tx8s::moveItems(items, envelop = nil)
    def self.moveItems(items, envelop = nil)
        if envelop.nil? then
            core = TxCores::interactivelySelectOneOrNull()
            if core then
                Tx8s::moveItems(items, core)
                return
            else
                return
            end
        end

        child = Catalyst::selectChildUnderneathParentOrNull(envelop)

        if child and child["mikuType"] == "NxThread" then
            Tx8s::moveItems(items, child)
            return
        else
            items.each{|item|
                position = Tx8s::decide1020position(envelop)
                tx8 = Tx8s::make(envelop["uuid"], position)
                puts JSON.pretty_generate(tx8)
                Cubes::setAttribute2(item["uuid"], "parent", tx8)
            }
        end
    end

    # Tx8s::selectChildrenAndMove(parent)
    def self.selectChildrenAndMove(parent)
        selected, _ = LucilleCore::selectZeroOrMore("elements", [], Tx8s::childrenInOrder(parent), lambda{|item| PolyFunctions::toString(item) })
        return if selected.empty?
        Tx8s::moveItems(items)
    end
end
