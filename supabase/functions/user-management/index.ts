import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4'

interface Database {
  public: {
    Tables: {
      user_profiles: {
        Row: {
          id: string
          display_name: string | null
          avatar_url: string | null
          currency: string
          date_format: string
          first_day_of_week: number
          created_at: string
          updated_at: string
          version: number
          is_deleted: boolean
          device_id: string | null
          last_editor: string | null
        }
        Insert: Omit<Database['public']['Tables']['user_profiles']['Row'], 'created_at' | 'updated_at' | 'version'>
        Update: Partial<Database['public']['Tables']['user_profiles']['Insert']>
      }
      categories: {
        Row: {
          id: string
          name: string
          icon: string | null
          color: string
          user_id: string | null
          created_at: string
          updated_at: string
          version: number
          is_deleted: boolean
          device_id: string | null
          last_editor: string | null
        }
      }
      accounts: {
        Row: {
          id: string
          name: string
          type: string
          balance: number
          user_id: string | null
          created_at: string
          updated_at: string
          version: number
          is_deleted: boolean
          device_id: string | null
          last_editor: string | null
        }
      }
      expenses: {
        Row: {
          id: string
          title: string
          amount: number
          category_id: string | null
          account_id: string | null
          date: string
          description: string | null
          receipt_photo_id: string | null
          user_id: string | null
          created_at: string
          updated_at: string
          version: number
          is_deleted: boolean
          device_id: string | null
          last_editor: string | null
        }
      }
      budgets: {
        Row: {
          id: string
          name: string
          amount: number
          category_id: string | null
          period: string
          start_date: string | null
          end_date: string | null
          user_id: string | null
          created_at: string
          updated_at: string
          version: number
          is_deleted: boolean
          device_id: string | null
          last_editor: string | null
        }
      }
      financial_goals: {
        Row: {
          id: string
          user_id: string
          title: string
          description: string | null
          target_amount: number
          current_amount: number
          target_date: string | null
          category_id: string | null
          is_achieved: boolean
          created_at: string
          updated_at: string
          version: number
          is_deleted: boolean
          device_id: string | null
          last_editor: string | null
        }
      }
    }
  }
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient<Database>(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        auth: {
          persistSession: false,
        },
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the authenticated user
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const url = new URL(req.url)
    const action = url.searchParams.get('action')

    switch (action) {
      case 'initialize-profile':
        return await initializeUserProfile(supabaseClient, user.id, req)
      
      case 'migrate-anonymous-data':
        return await migrateAnonymousData(supabaseClient, user.id, req)
      
      case 'delete-user-data':
        return await deleteUserData(supabaseClient, user.id, req)
      
      case 'get-user-stats':
        return await getUserStats(supabaseClient, user.id)
      
      case 'update-profile':
        return await updateUserProfile(supabaseClient, user.id, req)
      
      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action parameter' }),
          { 
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
    }

  } catch (error) {
    console.error('Error in user-management function:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

async function initializeUserProfile(supabaseClient: any, userId: string, req: Request) {
  try {
    const requestData = await req.json().catch(() => ({}))
    const { display_name, currency = 'USD', date_format = 'MM/dd/yyyy' } = requestData

    // Check if profile already exists
    const { data: existingProfile } = await supabaseClient
      .from('user_profiles')
      .select('id')
      .eq('id', userId)
      .single()

    if (existingProfile) {
      return new Response(
        JSON.stringify({ message: 'Profile already exists', profile_id: userId }),
        { 
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Create user profile
    const { error: profileError } = await supabaseClient
      .from('user_profiles')
      .insert({
        id: userId,
        display_name: display_name || null,
        currency,
        date_format,
        device_id: 'edge-function',
        last_editor: 'system'
      })

    if (profileError) {
      throw new Error(`Failed to create profile: ${profileError.message}`)
    }

    // Get shared categories to copy as user categories
    const { data: sharedCategories, error: categoriesError } = await supabaseClient
      .from('shared_categories')
      .select('name, icon, color')
      .eq('is_deleted', false)
      .order('sort_order')

    if (categoriesError) {
      console.error('Failed to fetch shared categories:', categoriesError)
    }

    // Create default personal categories
    if (sharedCategories && sharedCategories.length > 0) {
      const userCategories = sharedCategories.map((cat: any) => ({
        name: cat.name,
        icon: cat.icon,
        color: cat.color,
        user_id: userId,
        device_id: 'edge-function',
        last_editor: 'system'
      }))

      const { error: insertCategoriesError } = await supabaseClient
        .from('categories')
        .insert(userCategories)

      if (insertCategoriesError) {
        console.error('Failed to create user categories:', insertCategoriesError)
      }
    }

    // Create default cash account
    const { error: accountError } = await supabaseClient
      .from('accounts')
      .insert({
        name: 'Cash',
        type: 'cash',
        balance: 0.00,
        user_id: userId,
        device_id: 'edge-function',
        last_editor: 'system'
      })

    if (accountError) {
      console.error('Failed to create default account:', accountError)
    }

    return new Response(
      JSON.stringify({ 
        message: 'User profile initialized successfully',
        profile_id: userId,
        categories_created: sharedCategories?.length || 0,
        account_created: !accountError
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error initializing user profile:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to initialize profile', details: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function migrateAnonymousData(supabaseClient: any, userId: string, req: Request) {
  try {
    const requestData = await req.json().catch(() => ({}))
    const { device_id } = requestData

    if (!device_id) {
      return new Response(
        JSON.stringify({ error: 'device_id parameter is required' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Call the migration function
    const { data: migrationResult, error: migrationError } = await supabaseClient
      .rpc('migrate_anonymous_data_to_user', {
        target_user_id: userId,
        device_identifier: device_id
      })

    if (migrationError) {
      throw new Error(`Migration failed: ${migrationError.message}`)
    }

    return new Response(
      JSON.stringify({ 
        message: 'Anonymous data migration completed',
        migration_summary: migrationResult
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error migrating anonymous data:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to migrate data', details: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function deleteUserData(supabaseClient: any, userId: string, req: Request) {
  try {
    const requestData = await req.json().catch(() => ({}))
    const { confirm_deletion = false } = requestData

    if (!confirm_deletion) {
      return new Response(
        JSON.stringify({ error: 'confirm_deletion must be true to proceed' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Soft delete user data (mark as deleted rather than hard delete for data integrity)
    const tables = ['expenses', 'budgets', 'financial_goals', 'categories', 'accounts']
    const deletionResults: any = {}

    for (const table of tables) {
      const { error } = await supabaseClient
        .from(table)
        .update({ 
          is_deleted: true, 
          updated_at: new Date().toISOString(),
          last_editor: 'user-deletion'
        })
        .eq('user_id', userId)

      deletionResults[table] = error ? `Failed: ${error.message}` : 'Success'
    }

    // Soft delete user profile
    const { error: profileError } = await supabaseClient
      .from('user_profiles')
      .update({ 
        is_deleted: true, 
        updated_at: new Date().toISOString(),
        last_editor: 'user-deletion'
      })
      .eq('id', userId)

    deletionResults['user_profiles'] = profileError ? `Failed: ${profileError.message}` : 'Success'

    return new Response(
      JSON.stringify({ 
        message: 'User data deletion completed',
        deletion_results: deletionResults
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error deleting user data:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to delete user data', details: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function getUserStats(supabaseClient: any, userId: string) {
  try {
    // Get user profile
    const { data: profile } = await supabaseClient
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single()

    // Count user's data
    const { count: expenseCount } = await supabaseClient
      .from('expenses')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_deleted', false)

    const { count: budgetCount } = await supabaseClient
      .from('budgets')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_deleted', false)

    const { count: categoryCount } = await supabaseClient
      .from('categories')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_deleted', false)

    const { count: accountCount } = await supabaseClient
      .from('accounts')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_deleted', false)

    const { count: goalCount } = await supabaseClient
      .from('financial_goals')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_deleted', false)

    return new Response(
      JSON.stringify({
        profile,
        statistics: {
          total_expenses: expenseCount || 0,
          total_budgets: budgetCount || 0,
          total_categories: categoryCount || 0,
          total_accounts: accountCount || 0,
          total_financial_goals: goalCount || 0
        }
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error getting user stats:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to get user stats', details: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}

async function updateUserProfile(supabaseClient: any, userId: string, req: Request) {
  try {
    const requestData = await req.json()
    const allowedFields = ['display_name', 'avatar_url', 'currency', 'date_format', 'first_day_of_week']
    
    // Filter only allowed fields
    const updateData: any = {}
    for (const field of allowedFields) {
      if (requestData[field] !== undefined) {
        updateData[field] = requestData[field]
      }
    }

    if (Object.keys(updateData).length === 0) {
      return new Response(
        JSON.stringify({ error: 'No valid fields to update' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    updateData.last_editor = 'user-update'

    const { data, error } = await supabaseClient
      .from('user_profiles')
      .update(updateData)
      .eq('id', userId)
      .select()
      .single()

    if (error) {
      throw new Error(`Failed to update profile: ${error.message}`)
    }

    return new Response(
      JSON.stringify({ 
        message: 'Profile updated successfully',
        profile: data
      }),
      { 
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error updating profile:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to update profile', details: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}