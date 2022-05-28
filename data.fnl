{:unit-types {:warrior {:hp 20 :bump-damage 10}
              :shooter {:hp 15 :bump-damage 3}
              :pulse {:hp 15 :bump-damage 3}}
 :enemy-types {:basic {:hp 3 :bump-damage 2}
               :brute-1 {:hp 30 :bump-damage 5}}
 :levels
 [{:type :combat
   :group-options [[:basic :basic] [:basic :basic :basic]]
   :waves [{:groups 1}]}
  {:type :upgrade}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :basic :basic] [:brute-1]]
   :waves [{:groups 1} {:groups 2}]}
  {:type :upgrade}
  {:type :combat
   :group-options [[:basic :basic :brute-1] [:brute-1 :brute-1]]
   :waves [{:groups 2} {:groups 2}]}
  {:type :combat
   :group-options [[:basic :basic :brute-1] [:basic :basic :basic :basic :basic :basic :basic :basic] [:brute-1 :brute-1]]
   :waves [{:groups 2} {:groups 2} {:groups 2}]}
  {:type :upgrade}]}
