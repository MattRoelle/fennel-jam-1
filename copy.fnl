(local copy
       {:en
        {:units
         {:warrior "Charges at a random enemy every 1 second"
          :shooter "Shoots at a random enemy every 2 seconds"}
         :enemies
         {:basic "Charges at a random unit every 1 second"}}})


(λ get-copy-str [lang category ...]
  (?. copy lang category ...))

{: copy
 : get-copy-str}
