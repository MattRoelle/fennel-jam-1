(local copy
       {:en
        {:units
         {:warrior "Charges at random enemy"
          :shooter "Shoots at random enemy"
          :pulse "Shoots a burst at units in range"}
         :enemies
         {:basic "Charges at a random unit every 1 second"}}})


(λ get-copy-str [lang category ...]
  (?. copy lang category ...))

{: copy
 : get-copy-str}
