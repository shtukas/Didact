
# encoding: UTF-8

require 'json'
# JSON.pretty_generate(object)

require 'date'
require 'time'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(5) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'colorize'

require 'sqlite3'

require 'find'

require 'thread'

require 'colorize'

require 'drb/drb'

# ------------------------------------------------------------

checkLocation = lambda{|location|
    if !File.exist?(location) then
        puts "I cannot see location: #{location.green}"
        exit
    end
} 

checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/Stargate-Config.json")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataBank/catalyst/NxBalls")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataHub/NxTasks-FrontElements-BufferIn")
checkLocation.call("#{ENV['HOME']}/Galaxy/DataHub/catalyst")
checkLocation.call("#{ENV['HOME']}/Galaxy/Software/Lucille-Ruby-Libraries")
checkLocation.call("#{ENV['HOME']}/x-space/xcache-v1-days")

# ------------------------------------------------------------

require_relative "Config.rb"

require "#{Config::userHomeDirectory()}/Galaxy/Software/Lucille-Ruby-Libraries/LucilleCore.rb"

require "#{Config::userHomeDirectory()}/Galaxy/Software/Lucille-Ruby-Libraries/XCache.rb"
=begin
    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)

    XCache::setFlag(key, flag)
    XCache::getFlag(key)

    XCache::filepath(key)
=end

require "#{Config::userHomeDirectory()}/Galaxy/Software/Lucille-Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .putBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set("SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = XCache::getOrNull(nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end

end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHashRaiseErrorIfAny(operator, nhash)

=end

require "#{Config::userHomeDirectory()}/Galaxy/Software/Lucille-Ruby-Libraries/Blades.rb"

=begin
Blades

    Blades::decideInitLocation(uuid)
    Blades::locateBladeUsingUUID(uuid)

    Blades::init(uuid)
    Blades::setAttribute(token, attribute_name, value)
    Blades::getAttributeOrNull(token, attribute_name)
    Blades::addToSet(token, set_id, element_id, value)
    Blades::removeFromSet(token, set_id, element_id)
    Blades::putDatablob(token, key, datablob)
    Blades::getDatablobOrNull(token, key)
=end

class Blades

    # Blades::decideInitLocation(uuid)
    def self.decideInitLocation(uuid)
        "#{Config::pathToCatalystData()}/Blades/#{uuid}.blade"
    end

    # Blades::locateBladeUsingUUID(uuid)
    def self.locateBladeUsingUUID(uuid)
        "#{Config::pathToCatalystData()}/Blades/#{uuid}.blade"
    end
end

require "#{Config::userHomeDirectory()}/Galaxy/Software/Lucille-Ruby-Libraries/MikuTypes.rb"

=begin
MikuTypes
    MikuTypesCore::bladesEnumerator(roots)
    MikuTypesCore::mikuTypedBladesEnumerator(roots)
    MikuTypesCore::mikuTypeBladesEnumerator(roots, mikuType)
    MikuTypesCore::scan(roots)
    MikuTypesCore::scanMonitor(roots, periodInSeconds)
    MikuTypesCore::mikuTypeFilepaths(mikuType)
=end

MikuTypesCore::scanMonitor(["#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Blades"], 3600)

# ------------------------------------------------------------

require_relative "Anniversaries.rb"

require_relative "BankCore.rb"
require_relative "BankUtils.rb"

require_relative "Catalyst.rb"
require_relative "CoreData.rb"
require_relative "CommonUtils.rb"

require_relative "DoNotShowUntil.rb"
# DoNotShowUntil::setUnixtime(item, unixtime)
# DoNotShowUntil::isVisible(item)
require_relative "Dx8Units.rb"
require_relative "Desktop"
require_relative "DevicesBackups.rb"

require_relative "Galaxy.rb"

require_relative "Interpreting.rb"
require_relative "ItemStore.rb"

require_relative "LambdX1s.rb"
require_relative "Listing.rb"

require_relative "NxBalls.rb"
require_relative "NxOndates.rb"
require_relative "NxPlanets.rb"
require_relative "NxTasks.rb"
require_relative "NxNote.rb"
require_relative "NxOpenCycles.rb"
require_relative "N1Data.rb"
require_relative "NxTimePromises.rb"
require_relative "N3Objects.rb"
require_relative "NxFires.rb"
require_relative "NxFloats.rb"

require_relative "PrimitiveFiles.rb"
require_relative "ProgrammableBooleans.rb"
require_relative "PolyActions.rb"
require_relative "PolyFunctions.rb"
require_relative "PhysicalTargets.rb"
require_relative "PriorityItems.rb"

require_relative "SectionsType0141.rb"
require_relative "Stargate.rb"

require_relative "TheLine.rb"
require_relative "Transmutations.rb"
require_relative "NxCliques.rb"
require_relative "TxEngine.rb"

require_relative "Waves.rb"

# ------------------------------------------------------------

$bank_database_semaphore = Mutex.new
$dnsu_database_semaphore = Mutex.new
$owner_items_mapping_database_semaphore = Mutex.new
$links_database_semaphore = Mutex.new
$arrows_database_semaphore = Mutex.new

# ------------------------------------------------------------