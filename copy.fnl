(local copy
       {:en
        {:upgrades
         {:shop+ "Shop Inventory + 1"
          :gold+ "+ 2 gold per turn"
          :bump+ "+ 1 to all bump damage"
          :ability+ "+ 1 to all non-bump damage"
          :heal+ "+ 1 to all heals"
          :shoot+ "+ 1 to number of projectiles fired by shooters"
          :spawn+ "+ 1 to number of objects spawned by spawners"}
         :units
         {:warrior "Charges at random enemy"
          :shooter "Shoots at random enemy"
          :shotgunner "Shoots a burst at random enemy"
          :pulse "Shoots a burst at units in range"}
         :enemies
         {:basic "Charges at a random unit every 1 second"}}})


(λ get-copy-str [lang category ...]
  (?. copy lang category ...))

{: copy
 : get-copy-str}
