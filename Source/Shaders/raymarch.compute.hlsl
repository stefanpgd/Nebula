struct Settings
{
    float time;
};
ConstantBuffer<Settings> settings : register(b0);
RWTexture2D<float4> backBuffer : register(u0);

float sdSphere(float3 p, float r)
{
    return length(p) - r;
}

float sdBox(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float smin(float a, float b, float k)
{
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

float DistanceInScene(float3 pointAlongRay)
{
    float3 s1P = float3(cos(settings.time) * 2.0, 0.0f, 0.0);
    float3 s2P = float3(0.0f, 0.0f, 0.0f);
    
    float3 p1 = pointAlongRay - s1P;
    float3 p2 = pointAlongRay - s2P;
    
    float d1 = sdSphere(p1, 0.75);
    float d2 = sdBox(p2, 0.5);
    
    float sceneDistance = smin(d2, d1, 1.25);
    
    return sceneDistance;
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