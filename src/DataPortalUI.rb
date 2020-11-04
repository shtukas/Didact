# encoding: UTF-8

class DataPortalUI
    # DataPortalUI::dataPortalFront()
    def self.dataPortalFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item(
                "General Exploration", 
                lambda { GeneralSearch::searchAndDive() }
            )

            ms.item(
                "General Exploration (ncurses experimental)", 
                lambda { 
                    puts "Not implemented yet"
                    LucilleCore::pressEnterToContinue()
                }
            )

            puts ""

            ms.item("OpsListings",lambda { OpsListings::main() })

            ms.item("KnowledgeNodes",lambda { KnowledgeNodes::main() })

            puts ""

            ms.item("Waves", lambda { Waves::main() })

            ms.item("Asteroids", lambda { Asteroids::main() })

            ms.item(
                "Calendar",
                lambda { 
                    system("open '#{Calendar::pathToCalendarItems()}'") 
                }
            )

            puts ""

            ms.item("new datapoint", lambda {
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                description = LucilleCore::askQuestionAnswerAsString("datapoint description ? (empty for null) : ")
                if description.size > 0 then
                    if GenericNyxObject::isQuark(object) then
                        Quarks::setDescription(object)
                    end
                    if GenericNyxObject::isNGX15(object) then
                        datapoint["description"] = description
                        NyxObjects2::put(datapoint)
                    end
                end
                NGX15::landing(node)
            })

            puts ""

            ms.item("dangerously edit a nyx object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = NyxObjects2::getOrNull(uuid)
                return if object.nil?
                object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                NyxObjects2::put(object)
            })

            ms.item("dangerously delete a nyx object by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = NyxObjects2::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                NyxObjects2::destroy(object)
            })

            puts ""

            ms.item(
                "rebuild search lookup", 
                lambda { SelectionLookupDataset::rebuildDataset(true) }
            )

            ms.item(
                "NyxGarbageCollection::run()",
                lambda { NyxGarbageCollection::run() }
            )

            ms.item(
                "NyxFsck::main(runhash)",
                lambda {
                    runhash = LucilleCore::askQuestionAnswerAsString("run hash (empty to generate a random one): ")
                    if runhash == "" then
                        runhash = SecureRandom.hex
                    end
                    status = NyxFsck::main(runhash)
                    if status then
                        puts "All good".green
                    else
                        puts "Failed!".red
                    end
                    LucilleCore::pressEnterToContinue()
                }
            )

            ms.item(
                "Print Generation Speed Report", 
                lambda { CatalystObjectsOperator::generationSpeedReport() }
            )

            ms.item(
                "Curation::session()", 
                lambda { Curation::session() }
            )

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end
end


