struct Settings
{
    float time;
    int geometryCount;
};
ConstantBuffer<Settings> settings : register(b0);
RWTexture2D<float4> backBuffer : register(u0);

struct RMGeometry
{
    uint type;
    float3 position;
    float radius;
};
RWStructuredBuffer<RMGeometry> geometry : register(u1);

float sdSphere(float3 p, float r)
{
    return length(p) - r;
}

float sdBox(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float DistanceInScene(float3 pointAlongRay)
{
    float worldDistance = 100000.0f;
    
    for(int i = 0; i < settings.geometryCount; i++)
    {
        float3 gPos = geometry[i].position;
        float3 pos = pointAlongRay - gPos;
        float r = geometry[i].radius;
        float gDistance = 100000.0f;
        
        switch(geometry[i].type)
        {
            case 0:
                gDistance = sdSphere(pos, r);
                break;
            
            case 1:
                gDistance = sdBox(pos, r);
                break;
        }
        
        worldDistance = min(worldDistance, gDistance);
    }
    
    return worldDistance;
}

[numthreads(8, 8, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
    // SETTINGS //
    int maxSteps = 80;
    float epsilon = 0.001f;
    float maxDistance = 1000.0f;
    
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
    
    float3 ro = float3(0.0, 0.0, -3.0f);
    float3 rd = normalize(float3(uv, 1.0));
    float t = 0.0f;
    
    float3 color = float3(0.0, 0.0, 0.0);
    
    for(int i = 0; i < maxSteps; i++)
    {
        float3 p = ro + rd * t;
        float d = DistanceInScene(p);
        t += d;
        
        color = float3(i, i, i) / float(maxSteps);
        
        if(d < epsilon || d > maxDistance)
        {
            break;
        }
    }
    
    backBuffer[dispatchThreadID.xy] = float4(color, 1.0f);
}