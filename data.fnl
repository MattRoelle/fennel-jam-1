{:unit-types
 ;; tier 1
 {:warrior {:tier 1 
            :ai-type :bump
            :classes [:warrior]
            :hp 30
            :bump-damage 10
            :shape-type :circle
            :radius 16
            :mass 5
            :bump-force 256
            :bump-timer 2}
  :shooter {:tier 1
            :ai-type :shoot
            :classes [:shooter]
            :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
            :hp 15
            :linear-damping 0.001
            :range 0.7
            :fire-speed 50
            :bump-damage 3
            :fire-rate 2.5}}
 ;; tier 2
 ;; :shotgunner {:ai-type :shoot :hp 15 :bump-damage 3 :tier 2}
 ;; :pulse {:ai-type :bump :hp 15 :bump-damage 3 :linear-damping 0 :tier 2}}
 :enemy-types
 {:basic {:hp 20
          :shape-type :circle
          :radius [9 14]
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
