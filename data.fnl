{:unit-types
 ;; tier 1
 {:bumper
  {:tier 1 
   :ai-type :bump
   :ability :bump
   :classes [:fighter]
   :hp 30
   :bump-damage 10
   :shape-type :circle
   :radius 16
   :mass 5
   :bump-force 256
   :color :bumper
   :defense 1
   :bump-timer 2}
  :healer
  {:tier 1 
   :defense 1
   :ai-type :float-ability
   :ability :heal
   :classes [:support]
   :hp 30
   :bump-damage 10
   :shape-type :polygon
   :points [-12 4 -12 -12 0 -12 10 0 0 12]
   :radius 16
   :linear-damping 0.001
   :mass 5
   :color :healer
   :attack-speed 2.5}
 ;:pusher
 ;{:tier 1 
 ; :defense 1
 ; :ai-type :float-ability
 ; :ability :push
 ; :classes [:fighter]
 ; :hp 30
 ; :bump-damage 10
 ; :shape-type :polygon
 ; :points [-12 4 -12 -12 0 -12 10 0 0 12]
 ; :radius 16
 ; :linear-damping 0.001
 ; :mass 5
 ; :color :bumper
 ; :bump-force 256
 ; :bump-timer 2
 ; :attack-speed 1.5}
  :shooter
  {:tier 1
   :defense 1
   :ai-type :float-ability
   :ability :shoot
   :color :shooter
   :classes [:shooter]
   :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
   :hp 15
   :linear-damping 0.001
   :range 0.7
   :fire-speed 50
   :bump-damage 3
   :attack-speed 2.5}}
 ;; tier 2
 ;; :shotgunner {:ai-type :shoot :hp 15 :bump-damage 3 :tier 2}
 ;; :pulse {:ai-type :bump :hp 15 :bump-damage 3 :linear-damping 0 :tier 2}}
 :enemy-types
 {:basic {:hp 20
          :shape-type :circle
          :radius [9 14]
          :color :enemy
          :bump-force 128
          :bump-damage 2
          :ai-type :bump}}
 :levels
 [{:type :combat
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
