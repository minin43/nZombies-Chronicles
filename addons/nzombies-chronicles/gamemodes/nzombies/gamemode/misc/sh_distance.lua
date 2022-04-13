-- Created by Ethorbit because I'm tired of these kinda things not
-- existing in the glua API and creating repetitive code
nzMisc = nzMisc or {}

function nzMisc:GetClosestEntityToPosition(pos, boolFunc, maxSearchDist)
    local lastDist
    local lastEnt

    for _,ent in pairs(maxSearchDist and ents.FindInSphere(pos, maxSearchDist) or ents.GetAll()) do
        if !isfunction(boolFunc) or boolFunc(ent) then
            local dist = lastDist and pos:DistToSqr(ent:GetPos()) or nil

            if !lastDist or dist < lastDist then
                lastDist = dist
                lastEnt = ent
            end
        end
    end

    return lastEnt
end
