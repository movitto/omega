# omega resources data
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega

# The resources module provides mechanisms to generate random resources
# from a fix list of resources supported by the system.
module Resources

RESOURCE_TYPE_METAL      = 'metal'
RESOURCE_TYPE_TEXTILE    = 'textile'
RESOURCE_TYPE_PLASTIC    = 'plastic'
RESOURCE_TYPE_ADHESIVE   = 'adhesive'
RESOURCE_TYPE_BIOPOLYMER = 'biopolymer'
RESOURCE_TYPE_WOOD       = 'wood'
RESOURCE_TYPE_GLASS      = 'glass'
RESOURCE_TYPE_GEM        = 'gem'
RESOURCE_TYPE_MINERAL    = 'mineral'
RESOURCE_TYPE_ELEMENT    = 'element'
RESOURCE_TYPE_FUEL       = 'fuel'

RESOURCE_TYPES  = [RESOURCE_TYPE_METAL, RESOURCE_TYPE_TEXTILE, RESOURCE_TYPE_PLASTIC, RESOURCE_TYPE_ADHESIVE, RESOURCE_TYPE_BIOPOLYMER, RESOURCE_TYPE_WOOD, RESOURCE_TYPE_GLASS, RESOURCE_TYPE_GEM, RESOURCE_TYPE_MINERAL, RESOURCE_TYPE_ELEMENT]

# Master resource dictionary of resource types to arrays of resources of those types
RESOURCE_NAMES  = { RESOURCE_TYPE_METAL      => ['steel', 'aluminum', 'copper', 'nickel', 'gold', 'silver', 'platinum'],
                    RESOURCE_TYPE_TEXTILE    => ['cotton', 'silk', 'wool', 'linen', 'hemp', 'nylon', 'polyester'],
                    RESOURCE_TYPE_PLASTIC    => ['plastic'],
                    RESOURCE_TYPE_ADHESIVE   => ['cellulose', 'rubber', 'casein', 'epoxy', 'cyanoacrylate', 'polyurethane', 'silicone'],
                    RESOURCE_TYPE_BIOPOLYMER => ['starch', 'sugar', 'cellulose'],
                    RESOURCE_TYPE_WOOD       => ['wood'],
                    RESOURCE_TYPE_GLASS      => ['glass'],
                    RESOURCE_TYPE_GEM        => ['amber', 'amethyst', 'beryl', 'coral', 'diamond', 'emeral', 'opal', 'jadeite', 'jasper', 'pearl', 'quartz', 'ruby', 'sapphire', 'topaz'],
                    RESOURCE_TYPE_MINERAL    => ['azurite', 'bismuth', 'calcite', 'euclase', 'geocronite', 'gypsum', 'howlite', 'inyoite', 'jarosite', 'kernite', 'lepidolite', 'manganite', 'neptunite', 'onyx', 'rutile', 'sulfur', 'xenotime', 'zincite'],
                    RESOURCE_TYPE_ELEMENT    => ['Hydrogen', 'Helium', 'Lithium', 'Beryllium', 'Boron', 'Carbon', 'Nitrogen', 'Oxygen', 'Fluorine', 'Neon', 'Sodium', 'Magnesium', 'Aluminum, Aluminium', 'Silicon', 'Phosphorus', 'Sulfur', 'Chlorine', 'Argon', 'Potassium', 'Calcium', 'Scandium', 'Titanium', 'Vanadium', 'Chromium', 'Manganese', 'Iron', 'Cobalt', 'Nickel', 'Copper', 'Zinc', 'Gallium', 'Germanium', 'Arsenic', 'Selenium', 'Bromine', 'Krypton', 'Rubidium', 'Strontium', 'Yttrium', 'Zirconium', 'Niobium', 'Molybdenum', 'Technetium', 'Ruthenium', 'Rhodium', 'Palladium', 'Silver', 'Cadmium', 'Indium', 'Tin', 'Antimony', 'Tellurium', 'Iodine', 'Xenon', 'Cesium', 'Barium', 'Lanthanum', 'Cerium', 'Praseodymium', 'Neodymium', 'Promethium', 'Samarium', 'Europium', 'Gadolinium', 'Terbium', 'Dysprosium', 'Holmium', 'Erbium', 'Thulium', 'Ytterbium', 'Lutetium', 'Hafnium', 'Tantalum', 'Tungsten', 'Rhenium', 'Osmium', 'Iridium', 'Platinum', 'Gold', 'Mercury', 'Thallium', 'Lead', 'Bismuth', 'Polonium', 'Astatine', 'Radon', 'Francium', 'Radium', 'Actinium', 'Thorium', 'Protactinium', 'Uranium', 'Neptunium', 'Plutonium', 'Americium', 'Curium', 'Berkelium', 'Californium', 'Einsteinium', 'Fermium', 'Mendelevium', 'Nobelium', 'Lawrencium', 'Rutherfordium', 'Dubnium', 'Seaborgium', 'Bohrium', 'Hassium', 'Meitnerium', 'Darmstadtium', 'Roentgenium', 'Copernicium'],
                    RESOURCE_TYPE_FUEL       => ['oil', 'uranium'] }

# Return string name corresponding to resource type constant.
#
# eg Omega::Resources.type_identifier(RESOURCE_TYPE_METAL) => 'metal'
def self.type_identifier(type)
  type.to_s.gsub(/RESOURCE_TYPE_/, "").downcase
end

# Return master list of resource identifiers generated from type / resources dictionary
RESOURCE_IDS   = RESOURCE_NAMES.collect { |type,list| list.collect { |name| self.type_identifier(type) + "-" + name } }.flatten

# Return {Cosmos::Resource} instantiated from random resource selected from master list
def self.random
  i = rand(RESOURCE_IDS.length-1)
  id = RESOURCE_IDS[i]
  Cosmos::Resource.new :material_id => id
end

# Return All {Cosmos::Resource}s instantiated from master list
def self.all_resources
  RESOURCE_IDS.collect { |i|
    Cosmos::Resource.new :material_id => i
  }
end

end # module Resources
end # module Omega
