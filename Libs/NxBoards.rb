class NxBoards

    # ---------------------------------------------------------
    # IO
    # ---------------------------------------------------------

    # NxBoards::items()
    def self.items()
        N3Objects::getMikuType("NxBoard")
    end

    # NxBoards::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxBoards::getItemFailIfMissing(uuid)
    def self.getItemFailIfMissing(uuid)
        board = NxBoards::getItemOfNull(uuid)
        return board if board
        raise "looking for a board that should exists. item: #{JSON.pretty_generate(item)}"
    end

    # NxBoards::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # ---------------------------------------------------------
    # Makers
    # ---------------------------------------------------------

    # This can only be called from nslog
    # NxBoards::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxBoard",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "engine"        => TxEngines::interactivelyMakeEngineOrNull()
        }
        NxBoards::commit(item)
        item
    end

    # ---------------------------------------------------------
    # Data
    # ---------------------------------------------------------

    # NxBoards::toString(item)
    def self.toString(item)
        "#{"(board)".green} #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxBoards::boardsOrdered()
    def self.boardsOrdered()
        NxBoards::items().sort{|i1, i2| TxEngines::completionRatio(i2["engine"]) <=> TxEngines::completionRatio(i2["engine"]) }
    end

    # NxBoards::listingItems()
    def self.listingItems()
        NxBoards::items()
            .map{|item| TxEngines::updateItemOrNothing(item) }
            .select{|item| TxEngines::completionRatio(item["engine"]) < 1 or NxBalls::itemIsRunning(item) }
    end

    # ---------------------------------------------------------
    # Ops
    # ---------------------------------------------------------

    # NxBoards::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxBoards::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxBoards::toString(item) })
    end

    # NxBoards::interactivelySelectOne()
    def self.interactivelySelectOne()
        loop {
            item = NxBoards::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # NxBoards::interactivelyDecideNewBoardPosition(board)
    def self.interactivelyDecideNewBoardPosition(board)
        boardItems = NxTasks::bItemsOrdered(board)
        return 1 if boardItems.empty?
        boardItems.each{|item| puts NxTasks::toString(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return boardItems.map{|item| item["position"] }.max + 1
        end
        return position.to_f
    end

    # ---------------------------------------------------------
    # Programs
    # ---------------------------------------------------------

    # NxBoards::programBoardListing(board)
    def self.programBoardListing(board)

        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(board, false)
            line = "(#{store.prefixString()}) #{NxBoards::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
            if NxBalls::itemIsActive(board) then
                line = line.green
            end
            spacecontrol.putsline line

            spacecontrol.putsline ""

            (Listing::items() + NxTasks::bItemsOrdered(board))
                .select{|item| item["boarduuid"] == board["uuid"] }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    spacecontrol.putsline(Listing::itemToListingLine(store, item))
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            break if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

    # NxBoards::programBoardActions(board)
    def self.programBoardActions(board)
        loop {
            board = NxBoards::getItemOfNull(board["uuid"])
            return if board.nil?
            puts NxBoards::toString(board)
            actions = ["start", "add time", "program(board)"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "start" then
                PolyActions::start(board)
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(board, timeInHours*3600)
            end
            if action == "program(board)" then
                NxBoards::programBoardListing(board)
            end
        }
    end

    # NxBoards::program()
    def self.program()
        loop {
            board = NxBoards::interactivelySelectOneOrNull()
            return if board.nil?
            NxBoards::programBoardActions(board)
        }
    end
end

class BoardsAndItems

    # BoardsAndItems::attachToItem(item, board or nil)
    def self.attachToItem(item, board)
        return if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
    end

    # BoardsAndItems::askAndMaybeAttach(item)
    def self.askAndMaybeAttach(item)
        return item if item["boarduuid"]
        return item if item["mikuType"] == "NxBoard"
        board = NxBoards::interactivelySelectOneOrNull()
        return item if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
        item
    end

    # BoardsAndItems::belongsToThisBoard1(item, board or nil)
    def self.belongsToThisBoard1(item, board)
        if board.nil? then
            item["boarduuid"].nil?
        else
            item["boarduuid"] == board["uuid"]
        end
    end

    # BoardsAndItems::belongsToThisBoard2ForListingManagement(item, board or nil or "all" or "managed")
    def self.belongsToThisBoard2ForListingManagement(item, board)
        if board == "all" then
            return true
        end
        if board == "managed" then
            if item["boarduuid"] then
                board = NxBoards::getItemOfNull(item["boarduuid"])
                if board then
                    if !DoNotShowUntil::isVisible(board) then
                        return false # we return false if the board is not visible
                    end
                    return TxEngines::completionRatio(board["engine"]) < 1
                else
                    return true
                end
            else
                return true
            end
        end
        BoardsAndItems::belongsToThisBoard1(item, board)
    end

    # BoardsAndItems::toStringSuffix(item)
    def self.toStringSuffix(item)
        return "" if item["boarduuid"].nil?
        board = NxBoards::getItemOfNull(item["boarduuid"])
        if board then
            " (board: #{board["description"].green})"
        else
            " (board: not found, boarduuid: #{item["boarduuid"]})"
        end
    end
end
