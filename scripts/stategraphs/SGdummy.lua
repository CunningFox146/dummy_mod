require("stategraphs/commonstates")

local states =
{
    State{
        name = "idle",
        tags = {"idle"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle")
        end,
    },
}

return StateGraph("dummy", states, {}, "idle", {})
