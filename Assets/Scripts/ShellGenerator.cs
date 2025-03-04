using UnityEngine;
using UnityEngine.Rendering;

public class ShellGenerator : MonoBehaviour
{
    [SerializeField] private Mesh originalMesh;
    private Mesh shellMesh;
    [SerializeField] private ComputeShader computeShader;
    [Range(2, 256)] [SerializeField] private int shellCount;
    [SerializeField] private float height;
    public bool generateShells = false;

    private void OnValidate()
    {
        if (generateShells)
        {
            GenerateShellMesh();
            //generateShells = false;
        }
    }

    public void GenerateShellMesh()
    {
        if (originalMesh != null)
        {
            #region SETUP BUFFERS
            ComputeBuffer vertexBuffer = new ComputeBuffer(originalMesh.vertexCount * shellCount, sizeof(float) * 3);
            vertexBuffer.SetData(originalMesh.vertices);

            ComputeBuffer triangleBuffer = new ComputeBuffer(originalMesh.triangles.Length * shellCount, sizeof(int));
            triangleBuffer.SetData(originalMesh.triangles);

            ComputeBuffer uvBuffer = new ComputeBuffer(originalMesh.uv.Length * shellCount, sizeof(float) * 2);
            uvBuffer.SetData(originalMesh.uv);
            
            ComputeBuffer normalBuffer = new ComputeBuffer(originalMesh.normals.Length * shellCount, sizeof(float) * 3);
            normalBuffer.SetData(originalMesh.normals);
            
            ComputeBuffer colorBuffer = new ComputeBuffer(originalMesh.vertexCount * shellCount, sizeof(float) * 4);
            #endregion

            #region INITIALIZE DATA FOR COMPUTE SHADER
            int triangleCount = originalMesh.triangles.Length / 3;
            
            computeShader.GetKernelThreadGroupSizes(0, out uint threadGroupSizeX, out _, out _);
            int threadGroupSize = Mathf.CeilToInt((float) triangleCount / threadGroupSizeX);
            
            computeShader.SetBuffer(0, "VertexBuffer", vertexBuffer);
            computeShader.SetBuffer(0, "TriangleBuffer", triangleBuffer);
            computeShader.SetBuffer(0, "UVBuffer", uvBuffer);
            computeShader.SetBuffer(0, "NormalBuffer", normalBuffer);
            computeShader.SetBuffer(0, "ColorBuffer", colorBuffer);
            
            computeShader.SetInt("ShellCount", shellCount);
            computeShader.SetInt("triangleCount", triangleCount);
            computeShader.SetInt("vertexCount", originalMesh.vertexCount);
            computeShader.SetFloat("height", height);
            
            computeShader.Dispatch(0, threadGroupSize, 1, 1);
            #endregion
            
            #region GET DATA FOR COMPUTE SHADER
            shellMesh = new Mesh();
            if (originalMesh.vertexCount * shellCount > 65535 && !originalMesh.indexFormat.Equals(IndexFormat.UInt32))
            {
                Debug.LogWarning("Shell mesh will exceed 16-bit index limit. Setting 32-bit indices.");
                shellMesh.indexFormat = IndexFormat.UInt32;
            }
            
            Vector3[] vertices = new Vector3[originalMesh.vertexCount * shellCount];
            int[] triangles = new int[originalMesh.triangles.Length * shellCount];
            Vector2[] uvs = new Vector2[originalMesh.uv.Length * shellCount];
            Vector3[] normals = new Vector3[originalMesh.vertexCount * shellCount];
            Color[] colors = new Color[originalMesh.vertexCount * shellCount];
            
            vertexBuffer.GetData(vertices);
            triangleBuffer.GetData(triangles);
            uvBuffer.GetData(uvs);
            normalBuffer.GetData(normals);
            colorBuffer.GetData(colors);
            
            shellMesh.SetVertices(vertices);
            shellMesh.SetTriangles(triangles, 0);
            shellMesh.SetUVs(0, uvs);
            shellMesh.SetNormals(normals);
            shellMesh.SetColors(colors);
            
            GetComponent<MeshFilter>().sharedMesh = shellMesh;
            #endregion

            #region RELEASE BUFFERS
            vertexBuffer.Release();
            triangleBuffer.Release();
            uvBuffer.Release();
            normalBuffer.Release();
            colorBuffer.Release();
            #endregion
        }
        else
        {
            Debug.LogError("The original mesh is missing");
        }
    }
}
