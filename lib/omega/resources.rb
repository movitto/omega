# omega resources data
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
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

def self.type_identifier(type)
  type.to_s.gsub(/RESOURCE_TYPE_/, "").downcase
end

RESOURCE_IDS   = RESOURCE_NAMES.collect { |type,list| list.collect { |name| self.type_identifier(type) + "-" + name } }.flatten

def self.rand_resource
  i = rand(RESOURCE_IDS.length-1)
  id = RESOURCE_IDS[i]
  type_name = id.split('-')
  type = type_name[0]
  name = type_name[1]

  Cosmos::Resource.new :type => type, :name => name
end

end # module Resources
end # module Omega
