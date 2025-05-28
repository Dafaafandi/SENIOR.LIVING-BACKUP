<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash; // Import Hash
use Illuminate\Validation\ValidationException; // Import ValidationException
use App\Models\User; // Import User model

class AuthController extends Controller
{
    /**
     * Handle user login request.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_name' => 'required|string',
        ]);

        $user = User::where('email', $request->email)
            ->with('patient')
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Email atau password salah.'
            ], 401);
        }

        // Optional: Clear existing tokens
        // $user->tokens()->delete();

        $token = $user->createToken($request->device_name)->plainTextToken;

        $userData = $user->toArray();
        if ($user->patient) {
            $userData['age'] = $user->patient->age;
            $userData['patient_id'] = $user->patient->id;
            $userData['birth_date'] = $user->patient->birth_date?->toDateString();
        }

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'user' => $userData,
            'token' => $token,
        ]);
    }

    /**
     * Get authenticated user data.
     */
    public function user(Request $request)
    {
        $user = $request->user();
        return response()->json(array_merge($user->toArray(), ['age' => $user->age]));
    }

    /**
     * Handle user logout request.
     */
    public function logout(Request $request)
    {
        // Hapus token yang digunakan untuk request ini
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout berhasil']);
    }

    /**
     * Handle user registration request (Optional).
     */
    public function register(Request $request)
    {
         $request->validate([
             'name' => 'required|string|max:255',
             'email' => 'required|string|email|max:255|unique:users',
             'password' => 'required|string|min:8|confirmed', // Memerlukan field password_confirmation
             'device_name' => 'required|string',
         ]);

         $user = User::create([
             'name' => $request->name,
             'email' => $request->email,
             'password' => Hash::make($request->password),
         ]);

         $token = $user->createToken($request->device_name)->plainTextToken;

         return response()->json([
             'message' => 'Registrasi berhasil',
             'user' => $user,
             'token' => $token,
         ], 201); // Status 201 Created
    }
}
