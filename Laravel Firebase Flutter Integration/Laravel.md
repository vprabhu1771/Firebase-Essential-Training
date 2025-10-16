Enable Sodium Extension

```
;extension=sodium
```

Change To

```
extension=sodium
```

```
php artisan make:migration add_player_id_to_users_table
```

# `.env`
```
FIREBASE_SERVICE_ACCOUNT = ""
```

```
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->text('player_id')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('player_id');
        });
    }
};
```
```
<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable, HasApiTokens;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',

        'player_id'
    ];
}
```

```
php artisan make:controller api/AuthController
```

```
<?php

namespace App\Http\Controllers\api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Storage;

use App\Models\User;
class AuthController extends Controller
{

     public function register(Request $request)
    {
        try {
            $request->validate([
                'name' => 'required|string|max:255',
                'email' => 'required|email|unique:users,email',
                'password' => 'required',
                'device_name' => 'required|string', // Add device_name validation
                'player_id' => 'nullable|string', // Optional if not always available
            ]);

            // $request->validate([
            //     'name' => 'required|string|max:255',
            //     'email' => 'required|email|unique:users,email',
            //     'password' => 'required|string|min:6',
            //     'device_name' => 'required|string', // Add device_name validation
            // ]);

            $user = User::create([
                'name' => $request->input('name'),
                'email' => $request->input('email'),
                'password' => Hash::make($request->input('password')),
                'player_id' => $request->player_id, // save the player_id
            ]);

            // Create token for device
            $token = $user->createToken($request->device_name)->plainTextToken;

            // Optional: send welcome notification
            if ($request->filled('player_id')) {
                $this->sendWelcomeNotification($request->player_id, $user->name);
            }

            return response()->json([
                'message' => 'User registered successfully',
                'user' => $user,
                'token' => $token,
            ], 201);

            // Issue a token with Sanctum and attach the device_name
            // $token = $user->createToken($request->input('device_name'))->plainTextToken;

            // return response()->json(['message' => 'User registered successfully', 'user' => $user, 'token' => $token], 201);
        } catch (ValidationException $e) {
            return response()->json(['error' => $e->validator->errors()], 422);
        }

    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_name' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        return $user->createToken($request->device_name)->plainTextToken;
    }
}
```

```
php artisan make:controller api/NotificationController
```

```
<?php

namespace App\Http\Controllers\api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Kreait\Firebase\Factory;
use App\Models\User;

class NotificationController extends Controller
{
    public function savePlayerId(Request $request)
    {
        // dd($request->all());
        $request->validate(['player_id' => 'required', 'user_id' => 'required']);
        $user = User::find($request->user_id);
        $user->update(['player_id' => $request->player_id]);
        return response()->json(['message' => 'Player ID saved']);
    }

    public function sendNotification(Request $request)
    {
        // dd(base_path());

        $request->validate([
            'title' => 'required|string',
            'body' => 'required|string',
            'player_id' => 'required|string',
        ]);
        
        $firebase = (new Factory)
            ->withServiceAccount(base_path(env('FIREBASE_SERVICE_ACCOUNT', 'firebase-adminsdk.json')))
            ->createMessaging();

        $message = [
            'notification' => [
                'title' => $request->title,
                'body' => $request->body,
            ],
            'token' => $request->player_id,
        ];

        $firebase->send($message);
        return response()->json(['message' => 'Notification sent']);
    }

    public function sendWelcomeNotification($playerId, $userName)
    {
        $firebase = (new Factory)
            ->withServiceAccount(base_path(env('FIREBASE_SERVICE_ACCOUNT', 'firebase-adminsdk.json')))
            ->createMessaging();

        $message = [
            'notification' => [
                'title' => 'Welcome to Our App!',
                'body' => "Hi {$userName}, thanks for joining us!",
            ],
            'token' => $playerId,
        ];

        try {
            $firebase->send($message);
        } catch (\Exception $e) {
            \Log::error('Failed to send notification: ' . $e->getMessage());
        }
    }
}
```

`api.php`
```
<?php

use App\Http\Controllers\api\AuthController;

Route::post('/login', [AuthController::class, 'login']);

use App\Http\Controllers\api\NotificationController;

Route::post('/save-player-id', [NotificationController::class, 'savePlayerId']);
Route::post('/send-notification', [NotificationController::class, 'sendNotification']);
```


## Postman

Let’s go through **how to test your Laravel Firebase NotificationController using Postman** — step by step.

---

## ✅ 1. Your Controller Summary

You have two endpoints:

### **1️⃣ Save Player ID**

```
POST /api/save-player-id
```

Stores a OneSignal/Firebase device token (`player_id`) for a given user.

### **2️⃣ Send Notification**

```
POST /api/send-notification
```

Sends a push notification to a given `player_id`.

---

## ✅ 2. Define Routes in `routes/api.php`

Add this:

```php
use App\Http\Controllers\api\NotificationController;

Route::post('/save-player-id', [NotificationController::class, 'savePlayerId']);
Route::post('/send-notification', [NotificationController::class, 'sendNotification']);
```

---

## ✅ 3. Testing in Postman

### 🧩 A. Save Player ID

**URL:**

```
http://127.0.0.1:8000/api/save-player-id
```

**Method:** `POST`
**Body (JSON):**

```json
{
  "user_id": 1,
  "player_id": "fcm_or_onesignal_token_here"
}
```

**Expected Response:**

```json
{
  "message": "Player ID saved"
}
```

✅ **What it does:**
Finds user with ID `1` and saves the token to the `player_id` column.

Make sure your `users` table has a `player_id` column:

```bash
php artisan make:migration add_player_id_to_users_table --table=users
```

In migration:

```php
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('player_id')->nullable();
    });
}
```

Then:

```bash
php artisan migrate
```

---

### 🧩 B. Send Notification

**URL:**

```
http://127.0.0.1:8000/api/send-notification
```

**Method:** `POST`
**Body (JSON):**

```json
{
  "title": "Hello from Laravel",
  "body": "This is a Firebase notification test",
  "player_id": "fcm_or_onesignal_token_here"
}
```

**Expected Response:**

```json
{
  "message": "Notification sent"
}
```

✅ **What it does:**

* Loads your Firebase Admin SDK JSON (`firebase-adminsdk.json`)
* Sends a notification to that token

---

## ✅ 4. Common Errors & Fixes

### ❌ Error:

`"The provided message is invalid."`

✅ Fix: Ensure your `$message` structure matches Firebase’s format:

```php
$message = [
    'token' => $request->player_id,
    'notification' => [
        'title' => $request->title,
        'body' => $request->body,
    ],
];
```

Or use Firebase’s message builder:

```php
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

$message = CloudMessage::withTarget('token', $request->player_id)
    ->withNotification(Notification::create($request->title, $request->body));

$firebase->send($message);
```

---

## ✅ 5. Double Check Your Firebase Setup

Ensure your service account file path is correct:

```
storage/app/firebase-adminsdk.json
```

And reference it in the controller like:

```php
->withServiceAccount(storage_path('app/firebase-adminsdk.json'))
```

---

Would you like me to show how to **trigger the same Laravel endpoint from your Flutter app** (to save and send notifications using the player ID)?
