{:upgrades
 {:shop! {}
  :gold! {}
  :reroll! {}
  :bump! {}
  :ability-dmg! {}
  :heal! {}
  :shoot! {}
  :spawn! {}}
 :unit-types
 ;; tier 99, spawns
 {:lildoink
  {:tier 99 
   :defense 1
   :classes [:spawner]
   :hp 10
   :damage 1
   :shape-type :circle
   :radius 6
   :mass 1
   :color :bumper
   :bump-timer 2}
  ;; tier 1
  :banker
  {:tier 1 
   :defense 1
   :hp 50
   :damage 3
   :classes [:traders]
   :shape-type :circle
   :radius 20
   :mass 5
   :color :merchant
   :bump-timer 2}
  :shopkeeper
  {:tier 1 
   :defense 1
   :hp 50
   :damage 3
   :classes [:traders]
   :shape-type :circle
   :radius 20
   :mass 5
   :color :merchant
   :bump-timer 2}
  :fighter
  {:tier 1 
   :defense 1
   :hp 50
   :damage 3
   :classes [:bumpers]
   :shape-type :circle
   :radius 20
   :mass 5
   :color :bumper
   :bump-timer 2}
  :spinner
  {:tier 1 
   :defense 1
   :hp 50
   :damage 3
   :classes [:spawners]
   :shape-type :circle
   :radius 16
   :mass 5
   :color :bumper
   :bump-timer 2}
  :spawner
  {:tier 1 
   :defense 0
   :hp 5
   :damage 1
   :mass 1
   :ability-speed 2.5
   :classes [:spawners]
   :shape-type :polygon
   :points [-12 0 -12 -12 0 -12 18 18]
   :color :healer}
  :healer
  {:tier 1 
   :defense 0
   :hp 5
   :damage 1
   :mass 1
   :ability-speed 2.5
   :classes [:supporters]
   :shape-type :polygon
   :points [-12 4 -12 -12 0 -12 10 0 0 12]
   :color :healer}
  :bomber
  {:tier 1
   :defense 1
   :hp 5
   :damage 1
   :mass 1
   :ai-type :float-ability
   :ability :drop-bomb
   :color :shooter
   :classes [:spawners]
   :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
   :linear-damping 0.001
   :range 0.7
   :fire-speed 50
   :ability-speed 0.3}
  :sniper
  {:tier 1
   :defense 1
   :hp 5
   :damage 1
   :mass 1
   :ai-type :float-ability
   :ability :snipe
   :color :shooter
   :classes [:shooters]
   :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
   :linear-damping 0.001
   :range 0.7
   :fire-speed 50
   :ability-speed 0.3}
  :shooter
  {:tier 1
   :defense 1
   :hp 5
   :damage 1
   :mass 1
   :ai-type :float-ability
   :ability :shoot
   :color :shooter
   :classes [:shooters]
   :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
   :linear-damping 0.001
   :range 0.7
   :fire-speed 50
   :ability-speed 0.3}}
 ;; tier 2
 ;; :shotgunner {:ai-type :shoot :hp 15 :damage 3 :tier 2}
 ;; :pulse {:ai-type :bump :hp 15 :damage 3 :linear-damping 0 :tier 2}}
 :enemy-types
 {:basic {:hp 30
          :damage 2
          :defense 0
          :shape-type :circle
          :radius [9 14]
          :color :enemy
          :bump-force 128
          :ai-type :enemy}}
 :levels
 [{:type :upgrade}
  {:type :upgrade}
  {:type :upgrade}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic] [:basic :basic :basic]]
   :waves [{:groups 2}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic] [:basic :basic :basic]]
   :waves [{:groups 2} {:groups 3}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic] [:basic :basic :basic :basic :basic :basic :basic :basic]]
   :waves [{:groups 3} {:groups 4}]}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic] [:basic :basic :basic :basic :basic :basic :basic :basic] [:basic :basic]]
   :waves [{:groups 4} {:groups 4} {:groups 4}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic :basic :basic
                    :basic :basic :basic :basic
                    :basic :basic :basic :basic :basic
                    :basic :basic]]
   :waves [{:groups 2}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic :basic :basic
                    :basic :basic :basic :basic
                    :basic :basic :basic :basic :basic
                    :basic :basic]]
   :waves [{:groups 2}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic :basic :basic
                    :basic :basic :basic :basic
                    :basic :basic :basic :basic :basic
                    :basic :basic]]
   :waves [{:groups 2}]}
  {:type :upgrade}]}
