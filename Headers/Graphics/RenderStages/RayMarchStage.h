#pragma once
#include "Graphics/RenderStage.h"
#include "Framework/Mathematics.h"

class Texture;
class DXStructuredBuffer;

enum RayMarchType
{
	Sphere,
	Cube
};

struct RayMarchGeometry
{
	unsigned int Type;
	glm::vec3 Position;
	float radius = 1.0f;
};

struct RayMarchStageSettings
{
	float ElaspedTime;
	unsigned int GeometryCount;
};

class RayMarchStage : public RenderStage
{
public:
	RayMarchStage();

	void Update(float deltaTime);
	void RecordStage(ComPtr<ID3D12GraphicsCommandList4> commandList) override;

private:
	void InitializeResources();
	void InitializePipeline();

private:
	RayMarchStageSettings settings;

	std::vector<RayMarchGeometry> geometry;

	DXStructuredBuffer* geometryBuffer;
	Texture* backBuffer;
};