class Apachas

  def self.match(w1, w2)
    w1.downcase.strip == w2.downcase.strip
  end

  def self.match_nombre(names, entry)
    entry = entry.upcase
    [
      proc{|name, entry| match(name.upcase, entry) },
      proc{|name, entry| match(name.upcase.scan(/\w+/).first, entry) },
      proc{|name, entry| name.upcase.scan(/\w+/).collect{|w| w.chars.first } * "" == entry },
      proc{|name, entry| name.upcase.scan(/\w+/).first.chars.first == entry },
    ].each do |test|
      names.each do |name|
        return name if test.call(name, entry)
      end
    end

    return entry
  end

  def self.parsea_nombres(data)
    nombres = []
    otros = 0
    data.each_line do |line|
      next if line.strip.empty?

      if line =~ /^\s*\d+\s*$/
        otros = line.to_i
      else
        nombres << line.strip
      end
    end

    [nombres, otros]
  end


  def self.parsea_datos(datos, nombres)

    info = []
    datos.each_line do |line|
      next if line.strip.empty?
      nombre, beneficiarios, cantidad, concepto, comentario = line.strip.split(/\s+/)
      if beneficiarios != "*"
        beneficiarios = beneficiarios.split(/[,\s]+/).collect{|n| match_nombre(nombres, n)}
      end
      nombre = match_nombre(nombres, nombre) || nombre
      info << {:nombre => nombre, :beneficiarios => beneficiarios, :cantidad => cantidad.to_f, :concepto => concepto, :comentario => comentario}
    end

    (nombres - info.collect{|h| h[:nombre] }).each do |nombre|
      info << {:nombre => nombre, :beneficiarios => '*', :cantidad => 0, :concepto => ""}
    end

    info
  end
    

  def self.parsea(data)
    nombres_txt, datos_txt = data.split(/\@/)

    if datos_txt.nil? || datos_txt.empty?
      datos_txt = nombres_txt
      nombres_txt = nil
    end

    if nombres_txt
      nombres, otros = parsea_nombres(nombres_txt) if nombres_txt
    else
      nombres = []
      otros   = 0
    end

    pagos = parsea_datos(datos_txt, nombres)

    gente = nombres.length + otros
    total = pagos.inject(0){|acc,e| acc+=e[:cantidad]}

    {:gente => gente, :pagos => pagos}
  end

  def self.balance(info)
    gente = info[:gente]
    pagos = info[:pagos]

    nombres = (pagos.collect{|pago| pago[:nombre] } + pagos.collect{|pago| pago[:beneficiarios]}.flatten).uniq - ['*'] 

    gente = nombres.length if nombres.length > gente

    balance = {}
    nombres.each do |nombre| balance[nombre] = {:pago => 0, :debe => 0} end
    balance[:otro] = {:pago => 0, :debe => 0, :cantidad => gente - nombres.length} if nombres.length < gente

    pagos.each do |pago|
      nombre = pago[:nombre]
      beneficiarios = pago[:beneficiarios]
      cantidad = pago[:cantidad]

      balance[nombre][:pago] += cantidad

      if beneficiarios == "*"
        parte = cantidad / gente

        nombres.each do |beneficiario|
          balance[beneficiario][:debe] += parte
        end

        balance[:otro][:debe] += parte if balance[:otro]
      else
        parte = cantidad / beneficiarios.length
        beneficiarios.each do |beneficiario|
          balance[beneficiario][:debe] += parte
        end
      end
    end

    balance.each do |nombre, info|
      info[:diff] = info[:pago] - info[:debe]
    end

    balance
  end

  def self.print_balance(balance)
    data = balance.sort_by{|k,v| v[:diff]}.reverse.collect{|p|
       nombre, info = p

       "* #{ nombre }:\n" +
       "Balance: #{info[:diff]}\n" + 
       "Pag: #{info[:pago]}\n" + 
       "Gast: #{info[:debe]}"
    } * "\n-------\n"
    data
  end

  def self.procesa(str)
    print_balance balance parsea str
  end
end
