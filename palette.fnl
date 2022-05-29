(local {: rgba : hexcolor} (require :color))

(local index {})
(for [i 0 9]
  (tset index
        (.. "ix" (+ i 1))
        (rgba (/ i 10)
              (/ i 10)
              (/ i 10)
              1)))

(local default
       {:green (hexcolor :24c316ff)
        :teal (hexcolor :11818eff)
        :blue (hexcolor :07a8ffff)
        :blue (hexcolor :e940adff)
        :red (hexcolor :ff2626ff)
        :brown (hexcolor :e57e10ff)})

{: default
 : index}
