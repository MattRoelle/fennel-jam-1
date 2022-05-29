{:unit-types
 ;; tier 1
 {:warrior {:hp 30 :bump-damage 10 :radius 16 :mass 5
             :bump-force 1024 :bump-timer 3 :tier 1} 
  :shooter {:hp 15 :bump-damage 3 :tier 1 :fire-rate 2.5}
 ;; tier 2
  :shotgunner {:hp 15 :bump-damage 3 :tier 2}
  :pulse {:hp 15 :bump-damage 3 :linear-damping 0 :tier 2}}
 :enemy-types {:basic {:hp 3 :bump-damage 2}
                :brute-1 {:hp 30 :bump-damage 5}
                :square-1 {:hp 50 :bump-damage 5}}
 :levels
 [{:type :combat
   :group-options [[:basic :basic :basic :basic] [:basic :basic :basic]]
   :waves [{:groups 2}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic] [:basic :basic :square-1]]
   :waves [{:groups 2} {:groups 3}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :square-1 :square-1] [:square-1 :basic :basic :basic :basic :basic :basic :basic]]
   :waves [{:groups 3} {:groups 4}]}
  {:type :combat
   :group-options [[:basic :basic :brute-1 :basic :basic] [:basic :basic :basic :basic :basic :basic :basic :basic] [:brute-1 :brute-1]]
   :waves [{:groups 4} {:groups 4} {:groups 4}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic :basic :basic
                    :basic :basic :basic :basic
                    :square-1 :square-1 :square-1 :square-1 :square-1
                    :brute-1 :brute-1]]
   :waves [{:groups 2}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic :basic :basic
                    :basic :basic :basic :basic
                    :square-1 :square-1 :square-1 :square-1 :square-1
                    :brute-1 :brute-1]]
   :waves [{:groups 2}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic :basic :basic :basic :basic
                    :basic :basic :basic :basic
                    :square-1 :square-1 :square-1 :square-1 :square-1
                    :brute-1 :brute-1]]
   :waves [{:groups 2}]}
  {:type :upgrade}]}
