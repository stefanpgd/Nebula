struct Settings
{
    float time;
    int geometryCount;
};
ConstantBuffer<Settings> settings : register(b0);
RWTexture2D<float4> backBuffer : register(u0);

float N21(float2 uv)
{
    return frac(sin(uv.x * 18.28 + uv.y * 182.928) * 4782.282);
}

float smoothNoise(float2 uv, float scale)
{
    float2 lUV = frac(uv * scale);
    lUV = smoothstep(0.0, 1.0, lUV);
    
    float2 gID = floor(uv * scale);
    
    float2 bl = gID;
    float2 br = gID + float2(1.0, 0.0);
    float2 tl = gID + float2(0.0, 1.0);
    float2 tr = gID + float2(1.0, 1.0);
    
    float b = lerp(N21(bl), N21(br), lUV.x);
    float t = lerp(N21(tl), N21(tr), lUV.x);
    return lerp(b, t, lUV.y);
}

float Octave(float2 uv, float scale)
{
    float n = 0.0;
    
    n += smoothNoise(uv, scale);
    n += smoothNoise(uv, scale * 4.0) * 0.5;
    n += smoothNoise(uv, scale * 8.0) * 0.25;
    n += smoothNoise(uv, scale * 16.0) * 0.125;
    n += smoothNoise(uv, scale * 32.0) * 0.06125;
    
    n /= 1.756;
    return n;
}

float Terrain(float x, float z)
{
    float heightFactor = 0.0f;
    
    float baseFactor = 0.8;
    heightFactor += Octave(float2(x, z), baseFactor);
    
    return heightFactor;
}

float3 TerrainColor(float height)
{
    return lerp(float3(0.1, 0.1, 0.1), float3(0.7, 1.0, 0.5), height - 0.3);
}

float4 DistanceInScene(float3 pointAlongRay)
{
    float3 colorGeometry = float3(1.0, 1.0, 1.0);
    float terrainHeight = Terrain(pointAlongRay.x, pointAlongRay.z);
    
    float groundD = pointAlongRay.y - terrainHeight;
    
    return float4(TerrainColor(terrainHeight), groundD);
}

[numthreads(8, 8, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    // SETTINGS //
    int maxSteps = 250;
    float epsilon = 0.01f;
    float maxDistance = 100000.0f;
    
    uint width;
    uint height;
    backBuffer.GetDimensions(width, height);

    if(dispatchThreadID.x > width || dispatchThreadID.y > height)
    {
        return;
    }
    
    // UV coords //
    float2 uv = (dispatchThreadID.xy / float2(width, height)) * 2.0 - 1.0;
    uv.y *= -1.0f;
    uv.x *= float(width) / float(height); // Aspect Ratio
    
    float3 ro = float3(0.0, 0.48, -3.0f);
    float3 rd = normalize(float3(uv, 1.25));
    float t = 0.0f;
    
    float3 color = float3(0.0, 0.0, 0.0);
    
    for(int i = 0; i < maxSteps; i++)
    {
        float3 p = ro + rd * t;
        float4 scene = DistanceInScene(p);
        t += scene.a;
        
        if(scene.a < epsilon)
        {
            // Hit Surface //
            color = scene.rgb;
            break;
        }
        
        if(scene.a > maxDistance || i == maxSteps - 1)
        {
            break;
        }
    }
    
    float absorption = 0.35;
    float beersLaw = 1.0 - exp(-t * absorption);
    
    float3 skyColor = lerp(float3(0.52f, 0.75f, 1.0f), float3(0.85f, 0.9f, 1.0f), abs(rd.y));
    color = lerp(color, skyColor, beersLaw);
    
    backBuffer[dispatchThreadID.xy] = float4(color, 1.0f);
}