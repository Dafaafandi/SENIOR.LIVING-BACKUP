<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Rupadana\ApiService\ApiService; // Pastikan namespace ini benar
use App\Http\Controllers\Api\AuthController;
// Tambahkan use statement lain jika diperlukan

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Rute publik (tidak memerlukan autentikasi)
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']); // Jika Anda punya endpoint register

// Rute yang dilindungi (memerlukan autentikasi Sanctum)
Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/user', function (Request $request) {
        return $request->user()->loadMissing('patient');
    });

    // Mendaftarkan semua API service dari config/api-service.php
    $apiServiceClasses = config('api-service', []);

    if (!is_array($apiServiceClasses)) {
        \Log::error("Config 'api-service' is not returning an array. Please check config/api-service.php.");
    } else {
        foreach ($apiServiceClasses as $configKey => $configValue) {
            $classString = null;

            // Menentukan nama kelas yang akan diregistrasi.
            // Umumnya, nama kelas adalah nilai ($configValue) dari entri array.
            // Contoh: 'users' => \App\Api\UserApiService::class  ATAU  0 => \App\Api\UserApiService::class
            if (is_string($configValue)) {
                $classString = $configValue;
            } else {
                // Jika $configValue bukan string, berarti ada format yang salah di config.
                // Ini adalah penyebab error "Argument #1 ($class) must be of type string, array given"
                // jika $configValue adalah array dan langsung dilempar ke class_exists().
                \Log::warning("Invalid API service entry in config/api-service.php. Expected string class name as value, but received type: " . gettype($configValue) . " for config key/index: '{$configKey}'. Value: " . print_r($configValue, true) . ". Skipping this entry.");
                continue; // Lanjut ke entri berikutnya
            }

            if (!empty($classString) && class_exists($classString)) {
                ApiService::route($classString);
            } else {
                if (empty($classString)) {
                    \Log::error("Empty API service class string derived from config/api-service.php for config key/index: '{$configKey}'.");
                } else {
                    \Log::error("API Service class '{$classString}' (configured for key/index '{$configKey}') not found or is not a valid class name. Please check the namespace and class name in config/api-service.php.");
                }
            }
        }
    }

    // Contoh pendaftaran manual jika diperlukan (komentari jika tidak digunakan)
    // Route::apiResource('checkups', App\Http\Controllers\Api\CheckupApiController::class);
    // Route::apiResource('patients', App\Http\Controllers\Api\PatientApiController::class);
    // Route::get('/patients/{patient}/checkups', [App\Http\Controllers\Api\CheckupApiController::class, 'indexByPatient']);

});
