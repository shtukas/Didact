class PolyFunctions

    # PolyFunctions::itemsToBankingAccounts(item)
    def self.itemsToBankingAccounts(item)
        accounts = []

        if item["mikuType"] == "NxBoard" then
            accounts << {
                "description" => item["description"],
                "number"      => item["uuid"]
            }
            return accounts
        end

        if item["mikuType"] == "NxBoardItem" then
            accounts << {
                "description" => nil,
                "number"      => item["uuid"]
            }
            boarduuid = item["boarduuid"]
            stream = NxBoards::getItemOfNull(boarduuid)
            accounts << {
                "description" => "stream: #{stream["description"]}",
                "number"      => boarduuid
            }
            return accounts
        end

        if item["mikuType"] == "NxBoardFirstItem" then
            accounts << {
                "description" => "stream: #{item["stream"]["description"]}",
                "number"      => item["stream"]["uuid"]
            }
            accounts << {
                "description" => nil,
                "number"      => item["todo"]["uuid"]
            }
            return accounts
        end

        accounts << {
            "description" => nil,
            "number"      => item["uuid"]
        }

        board = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
        if board then
            accounts << {
                "description" => board["description"],
                "number"      => board["uuid"]
            }
        end

        accounts
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        if item["mikuType"] == "LambdX1" then
            return "(lambda) #{item["announce"]}"
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBoard" then
            return NxBoards::toString(item)
        end
        if item["mikuType"] == "NxBoardItem" then
            return NxBoardItems::toString(item)
        end
        if item["mikuType"] == "NxBoardFirstItem" then
            return item["description"]
        end
        if item["mikuType"] == "NxNode" then
            return NxNodes::toString(item)
        end
        if item["mikuType"] == "NxOpen" then
            return NxOpens::toString(item)
        end
        if item["mikuType"] == "NxOndate" then
            return NxOndates::toString(item)
        end
        if item["mikuType"] == "NxTail" then
            return NxTails::toString(item)
        end
        if item["mikuType"] == "NxHead" then
            return NxHeads::toString(item)
        end
        if item["mikuType"] == "NxTop" then
            return NxTops::toString(item)
        end
        if item["mikuType"] == "TxManualCountDown" then
            return "(countdown) #{item["description"]}: #{item["counter"]}"
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end
        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::toStringForSearchListing(item)
    def self.toStringForSearchListing(item)
        if item["mikuType"] == "Wave" then
            return Waves::toStringForSearch(item)
        end
        PolyFunctions::toString(item)
    end
end
