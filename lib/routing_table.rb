# Routing table
class RoutingTable
  include Pio

  MAX_NETMASK_LENGTH = 32

  def initialize(route)
    @db = Array.new(MAX_NETMASK_LENGTH + 1) { Hash.new }
    route.each { |each| add(each) }
  end

  def add(options)
    netmask_length = options.fetch(:netmask_length)
    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
    entry = @db[netmask_length][prefix.to_i]
    @db[netmask_length][prefix.to_i] = IPv4Address.new(options.fetch(:next_hop))
    if entry then
      print("success update entry\n")
    else
      print("success add entry\n")
    end
  end

  def lookup(destination_ip_address)
    MAX_NETMASK_LENGTH.downto(0).each do |each|
      prefix = destination_ip_address.mask(each)
      entry = @db[each][prefix.to_i]
      return entry if entry
    end
    nil
  end

  def delete(options)
    netmask_length = options.fetch(:netmask_length)
    prefix = IPv4Address.new(options.fetch(:destination)).mask(netmask_length)
    entry = @db[netmask_length][prefix.to_i]
    if entry then
      @db[netmask_length].delete(prefix.to_i)
      print("success delete entry\n")
    else
      print("error: not found entry")
    end
  end
    
  def show_table()
    print("---------- show routing table ----------\n")
    print("destination".rjust(16))
    print("next_hop".rjust(16))
    print("\n")
    @db.each_index do |netmask_length|
      @db[netmask_length].each do |prefix,next_hop|
        prefix_addr = IPv4Address.new(prefix).to_s
        print("#{prefix_addr}/#{netmask_length}".rjust(16))
        print("#{next_hop}".rjust(16))
        print("\n\n")
      end
    end
  end
end
