#include "Graphics/RenderStages/RayMarchStage.h"
#include "Graphics/DXRootSignature.h"
#include "Graphics/DXComputePipeline.h"
#include "Graphics/DXStructuredBuffer.h"
#include "Graphics/DXAccess.h"
#include "Graphics/DXUtilities.h"
#include "Graphics/Texture.h"
#include "Graphics/Window.h"

RayMarchStage::RayMarchStage()
{
	InitializeResources();
	InitializePipeline();
}

void RayMarchStage::Update(float deltaTime)
{
	settings.ElaspedTime += deltaTime;
}

void RayMarchStage::RecordStage(ComPtr<ID3D12GraphicsCommandList4> commandList)
{
	// 1. Bind our root signature & pipeine //
	commandList->SetComputeRootSignature(rootSignature->GetAddress());
	commandList->SetPipelineState(computePipeline->GetAddress());

	// 2. Bind resources needed for our pipeline //
	commandList->SetComputeRootDescriptorTable(0, backBuffer->GetUAV());
	commandList->SetComputeRootDescriptorTable(1, geometryBuffer->GetUAV());
	commandList->SetComputeRoot32BitConstants(2, 2, &settings, 0);

	// 3. Dispatch our compute shader //
	unsigned int screenWidth = DXAccess::GetWindow()->GetWindowWidth();
	unsigned int screenHeight = DXAccess::GetWindow()->GetWindowHeight();
	unsigned int dispatchX = screenWidth / 8;
	unsigned int dispatchY = screenHeight / 8;

	commandList->Dispatch(dispatchX, dispatchY, 1);

	// 4. Copy the result of our back buffer into the screen buffer //
	ComPtr<ID3D12Resource> screenBuffer = DXAccess::GetWindow()->GetCurrentScreenBuffer();

	TransitionResource(screenBuffer.Get(), D3D12_RESOURCE_STATE_RENDER_TARGET, D3D12_RESOURCE_STATE_COPY_DEST);
	commandList->CopyResource(screenBuffer.Get(), backBuffer->GetAddress());
	TransitionResource(screenBuffer.Get(), D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_RENDER_TARGET);
}

void RayMarchStage::InitializeResources()
{
	int width = DXAccess::GetWindow()->GetWindowWidth();
	int height = DXAccess::GetWindow()->GetWindowHeight();

	backBuffer = new Texture(width, height, DXGI_FORMAT_R8G8B8A8_UNORM);

	RayMarchGeometry sphere;
	sphere.Type = RayMarchType::Sphere;
	sphere.Position = glm::vec3(0.0f, 0.75f, 0.0f);

	RayMarchGeometry cube;
	cube.Type = RayMarchType::Cube;
	cube.Position = glm::vec3(0.0f, -0.75f, 0.0f);

	geometry.push_back(sphere);
	geometry.push_back(cube);
	geometryBuffer = new DXStructuredBuffer(geometry.data(), geometry.size(), sizeof(RayMarchGeometry));

	settings.GeometryCount = geometry.size();
}

void RayMarchStage::InitializePipeline()
{
	CD3DX12_DESCRIPTOR_RANGE1 bufferRange[1];
	bufferRange[0].Init(D3D12_DESCRIPTOR_RANGE_TYPE_UAV, 1, 0);

	CD3DX12_DESCRIPTOR_RANGE1 geometryRange[1];
	geometryRange[0].Init(D3D12_DESCRIPTOR_RANGE_TYPE_UAV, 1, 1);

	CD3DX12_ROOT_PARAMETER1 rootParameters[3];
	rootParameters[0].InitAsDescriptorTable(1, bufferRange);
	rootParameters[1].InitAsDescriptorTable(1, geometryRange);
	rootParameters[2].InitAsConstants(2, 0);

	rootSignature = new DXRootSignature(rootParameters, _countof(rootParameters));
	computePipeline = new DXComputePipeline(rootSignature, "Source/Shaders/raymarch.compute.hlsl");
}